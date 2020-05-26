use pathfinder_geometry::{rect::RectI, vector::Vector2I};
use pathfinder_gpu::{
    BlendFactor, BlendOp, BufferData, BufferTarget, BufferUploadMode, ComputeDimensions,
    ComputeState, DepthFunc, Device, FeatureLevel, Primitive, ProgramKind, RenderState,
    RenderTarget, ShaderKind, StencilFunc, TextureData, TextureDataRef, TextureFormat,
    TextureSamplingFlags, VertexAttrClass, VertexAttrDescriptor, VertexAttrType,
};
use pathfinder_resources::ResourceLoader;
use std::cell::Cell;
use std::cell::RefCell;
use std::convert::TryFrom;
use std::{collections::HashMap, mem, rc::Rc, slice, time::Duration};

#[derive(Debug)]
pub struct WebGpuDevice {
    device: wgpu::Device,
    queue: wgpu::Queue,

    /// This encoder is "finished" and inserted into `command_buffers` and replaced with a new one on `begin_commands` and `end_frame`. This ensures that there always is a current `command_encoder`.
    ///
    /// Note: maybe this is too "clever" and will cause bugs down the road. A more naive alternative would be `RefCell<Option<wgpu::CommandEncoder>>` and only having this be set between `begin_commands` and `end_commands`. Any additional work done by this implementation internally will just push new command buffers if this field is `None`.
    current_command_encoder: RefCell<wgpu::CommandEncoder>,
    command_buffers: RefCell<Vec<wgpu::CommandBuffer>>,
    main_depth_stencil_texture: wgpu::Texture,
    main_depth_stencil_texture_view: wgpu::TextureView,
    samplers: Vec<wgpu::Sampler>,
    swap_chain: wgpu::SwapChain,
    swap_chain_output: wgpu::SwapChainOutput,
    // From metal backend
    // layer: CoreAnimationLayer,
    // shared_event: SharedEvent,
    // shared_event_listener: SharedEventListener,
    // next_timer_query_event_value: Cell<u64>,
}

impl WebGpuDevice {
    pub fn new(window: impl raw_window_handle::HasRawWindowHandle, size: Vector2I) -> Self {
        futures::executor::block_on(async {
            let surface = wgpu::Surface::create(&window);

            let adapter = wgpu::Adapter::request(
                &wgpu::RequestAdapterOptions {
                    power_preference: wgpu::PowerPreference::Default,
                    compatible_surface: Some(&surface),
                },
                wgpu::BackendBit::PRIMARY,
            )
            .await
            .unwrap();

            let (device, queue) = adapter
                .request_device(&wgpu::DeviceDescriptor {
                    extensions: wgpu::Extensions {
                        anisotropic_filtering: false,
                    },
                    limits: wgpu::Limits::default(),
                })
                .await;

            let samplers = (0..16)
                .map(|sampling_flags_value| {
                    let sampling_flags =
                        TextureSamplingFlags::from_bits(sampling_flags_value).unwrap();

                    device.create_sampler(&wgpu::SamplerDescriptor {
                        address_mode_u: if sampling_flags.contains(TextureSamplingFlags::REPEAT_U) {
                            wgpu::AddressMode::Repeat
                        } else {
                            wgpu::AddressMode::ClampToEdge
                        },
                        address_mode_v: if sampling_flags.contains(TextureSamplingFlags::REPEAT_V) {
                            wgpu::AddressMode::Repeat
                        } else {
                            wgpu::AddressMode::ClampToEdge
                        },
                        address_mode_w: wgpu::AddressMode::ClampToEdge,
                        mag_filter: if sampling_flags.contains(TextureSamplingFlags::NEAREST_MAG) {
                            wgpu::FilterMode::Nearest
                        } else {
                            wgpu::FilterMode::Linear
                        },
                        min_filter: if sampling_flags.contains(TextureSamplingFlags::NEAREST_MIN) {
                            wgpu::FilterMode::Nearest
                        } else {
                            wgpu::FilterMode::Linear
                        },
                        mipmap_filter: wgpu::FilterMode::Nearest, // "Not mipmapped"
                        lod_min_clamp: 0.0,
                        lod_max_clamp: std::f32::MAX,
                        compare: wgpu::CompareFunction::Never,
                    })
                })
                .collect();

            let main_depth_stencil_texture = device.create_texture(&wgpu::TextureDescriptor {
                label: Some("main depth texture"),
                size: wgpu::Extent3d {
                    width: size.x().expect_unsigned(),
                    height: size.y().expect_unsigned(),
                    depth: 1,
                },
                mip_level_count: 1,
                sample_count: 1,
                dimension: wgpu::TextureDimension::D2,
                format: wgpu::TextureFormat::Depth24PlusStencil8,
                usage: wgpu::TextureUsage::OUTPUT_ATTACHMENT,
            });

            let mut swap_chain = device.create_swap_chain(
                &surface,
                &wgpu::SwapChainDescriptor {
                    usage: wgpu::TextureUsage::OUTPUT_ATTACHMENT,
                    format: wgpu::TextureFormat::Bgra8Unorm,
                    width: size.x().expect_unsigned(),
                    height: size.y().expect_unsigned(),
                    present_mode: wgpu::PresentMode::Fifo,
                },
            );

            let swap_chain_output = swap_chain.get_next_texture().unwrap();

            // A (potentially empty) command encoder to catch any internal backend work that happens before the first user call to `begin_commands`.
            let initialization_command_encoder =
                device.create_command_encoder(&wgpu::CommandEncoderDescriptor {
                    label: Some("init encoder"),
                });

            WebGpuDevice {
                device,
                queue,
                samplers,
                swap_chain,
                swap_chain_output,
                command_buffers: RefCell::new(Vec::new()),
                main_depth_stencil_texture_view: main_depth_stencil_texture.create_default_view(),
                main_depth_stencil_texture,
                current_command_encoder: RefCell::new(initialization_command_encoder),
            }
        })
    }

    /// Finishes the current command encoder and pushes it onto the frame's command buffers. Creates a new "current" command encoder that new commands should write to.
    fn finish_current_command_encoder(&self) {
        let next_command_encoder =
            self.device
                .create_command_encoder(&wgpu::CommandEncoderDescriptor {
                    label: Some("init encoder"),
                });
        let prev_command_encoder = self.current_command_encoder.replace(next_command_encoder);
        self.command_buffers
            .borrow_mut()
            .push(prev_command_encoder.finish());
    }

    fn borrow_current_command_encoder(&self) -> std::cell::RefMut<wgpu::CommandEncoder> {
        self.current_command_encoder.borrow_mut()
    }

    pub fn end_frame(&mut self) {
        self.finish_current_command_encoder();
        self.queue.submit(self.command_buffers.borrow().as_slice());
        self.command_buffers.borrow_mut().clear();
        self.swap_chain_output = self.swap_chain.get_next_texture().unwrap();
    }
}

#[derive(Debug, Clone)]
pub struct WebGpuBuffer {
    inner: LazilyInitialized<Rc<BufferStorage>>,
}

/// This exists because buffers are lazily initialized, but the size and buffer should be set at once.
#[derive(Debug)]
struct BufferStorage {
    buffer: wgpu::Buffer,
    size: usize,
}

#[derive(Debug)]
pub struct WebGpuFramebuffer(WebGpuTexture);

#[derive(Debug)]
pub struct WebGpuProgram {
    name: Option<String>,
    vertex_shader: WebGpuShader,
    fragment_shader: WebGpuShader,
}

#[derive(Debug)]
pub struct WebGpuShader {
    name: Option<String>,

    // bindings: (),
    shader_vertex_attributes: Option<HashMap<String, u32>>,
    /// TODO unneeded?
    kind: ShaderKind,
    module: wgpu::ShaderModule,
}

#[derive(Debug)]
pub struct WebGpuTexture {
    inner: wgpu::Texture,
    size: Vector2I,
    sampling_flags: Cell<TextureSamplingFlags>,
    format: TextureFormat,
    dirty: Cell<bool>,
}

/// For texture readback.
#[derive(Debug)]
pub struct WebGpuTextureDataReceiver {}

#[derive(Debug)]
pub struct WebGpuTimerQuery {}

#[derive(Debug)]
pub struct WebGpuUniform {
    name: String,
}

#[derive(Debug)]
pub struct WebGpuVertexArray {
    // todo use LazilyInitialized
    vertex_buffers: RefCell<Vec<VertexBuffer>>,
    index_buffer: RefCell<Option<WebGpuBuffer>>,
}

#[derive(Debug, Clone)]
struct VertexBuffer {
    buffer: WebGpuBuffer,
    stride: u64,
    step_mode: wgpu::InputStepMode,
    descriptor: Vec<wgpu::VertexAttributeDescriptor>,
}

#[derive(Debug)]
pub struct WebGpuVertexAttr {
    name: String,
    bind_location: u32,
}

#[derive(Debug, Clone)]
#[repr(transparent)]
struct LazilyInitialized<T>(RefCell<Option<T>>);

impl<T> LazilyInitialized<T> {
    pub fn uninitialized() -> Self {
        Self(RefCell::new(None))
    }

    pub fn initialize_with(&self, t: T) {
        let mut inner = self.0.borrow_mut();
        if inner.is_some() {
            panic!("already initialized");
        }
        *inner = Some(t);
    }

    pub fn initialize_or_replace_with(&self, t: T) -> Option<T> {
        self.0.borrow_mut().replace(t)
    }

    pub fn assume_init(&self) -> std::cell::Ref<T> {
        std::cell::Ref::map(self.0.borrow(), |a| {
            a.as_ref().expect("should be initialized")
        })
    }

    pub fn assume_init_mut(&self) -> std::cell::RefMut<T> {
        std::cell::RefMut::map(self.0.borrow_mut(), |a| {
            a.as_mut().expect("should be initialized")
        })
    }
}

/// Extension method for `i32` to reduce the code duplication of converting and unwrapping into a `u32`.
trait ExpectUnsigned {
    fn expect_unsigned(self) -> u32;
}

impl ExpectUnsigned for i32 {
    fn expect_unsigned(self) -> u32 {
        u32::try_from(self).expect("number must be unsigned")
    }
}

fn texture_format_to_wgpu(format: TextureFormat) -> wgpu::TextureFormat {
    match format {
        TextureFormat::R8 => wgpu::TextureFormat::R8Unorm,
        TextureFormat::R16F => wgpu::TextureFormat::R16Float,
        TextureFormat::RGBA8 => wgpu::TextureFormat::Rgba8Unorm,
        TextureFormat::RGBA16F => wgpu::TextureFormat::Rgba16Float,
        TextureFormat::RGBA32F => wgpu::TextureFormat::Rgba32Float,
    }
}

impl Device for WebGpuDevice {
    type Buffer = WebGpuBuffer;
    type Fence = ();
    type Framebuffer = WebGpuFramebuffer;
    type ImageParameter = ();
    type Program = WebGpuProgram;
    type Shader = WebGpuShader;
    type StorageBuffer = ();
    type Texture = WebGpuTexture;
    type TextureDataReceiver = WebGpuTextureDataReceiver;
    type TextureParameter = ();
    type TimerQuery = WebGpuTimerQuery;
    type Uniform = WebGpuUniform;
    type VertexArray = WebGpuVertexArray;
    type VertexAttr = WebGpuVertexAttr;

    fn feature_level(&self) -> FeatureLevel {
        FeatureLevel::D3D11
    }

    fn create_texture(&self, format: TextureFormat, size: Vector2I) -> Self::Texture {
        WebGpuTexture {
            inner: self.device.create_texture(&wgpu::TextureDescriptor {
                label: None,
                size: wgpu::Extent3d {
                    width: size.x().expect_unsigned(),
                    height: size.y().expect_unsigned(),
                    depth: 1,
                },
                mip_level_count: 1,
                sample_count: 1,
                dimension: wgpu::TextureDimension::D2,
                format: texture_format_to_wgpu(format),
                usage: wgpu::TextureUsage::UNINITIALIZED, // TODO
            }),
            size,
            format,
            sampling_flags: Cell::new(TextureSamplingFlags::empty()),
            dirty: Cell::new(false),
        }
    }

    fn create_texture_from_data(
        &self,
        format: TextureFormat,
        size: Vector2I,
        data: TextureDataRef,
    ) -> Self::Texture {
        let texture = self.create_texture(format, size);
        self.upload_to_texture(&texture, RectI::new(Vector2I::default(), size), data);
        texture
    }

    fn create_shader(
        &self,
        resources: &dyn ResourceLoader,
        name: &str,
        kind: ShaderKind,
    ) -> Self::Shader {
        let suffix = match kind {
            ShaderKind::Vertex => 'v',
            ShaderKind::Fragment => 'f',
            ShaderKind::Compute => 'c',
        };
        let path = format!("shaders/spirv/{}.{}s.spv", name, suffix);
        self.create_shader_from_source(name, &resources.slurp(&path).unwrap(), kind)
    }

    fn create_shader_from_source(
        &self,
        name: &str,
        source: &[u8],
        kind: ShaderKind,
    ) -> Self::Shader {
        let reflect_module = spirv_reflect::ShaderModule::load_u8_data(source).unwrap();
        let entry_point_name = reflect_module.get_entry_point_name();
        let shader_vertex_attributes = if reflect_module
            .get_shader_stage()
            .contains(spirv_reflect::types::variable::ReflectShaderStageFlags::VERTEX)
        {
            Some(
                reflect_module
                    .enumerate_input_variables(Some(&entry_point_name))
                    .unwrap()
                    .into_iter()
                    .filter_map(|interface_variable| {
                        // The naming convention in the shaders is that all attributes start with "a". `get_vertex_attr` drops this, so we will also drop the "a" so that string comparisons later will work.
                        // This also filters `gl_*` builtins.
                        if interface_variable.name.starts_with("a") {
                            Some((
                                interface_variable.name[1..].to_owned(),
                                interface_variable.location,
                            ))
                        } else {
                            None
                        }
                    })
                    .collect::<HashMap<String, u32>>(),
            )
        } else {
            None
        };

        for descriptor_binding in reflect_module.enumerate_descriptor_bindings(Some("main")) {
            dbg!(descriptor_binding);
        }

        // if name.starts_with("reproject") && kind == ShaderKind::Fragment {
        //     panic!();
        // }

        const SPIRV_WORD_LEN: usize = mem::size_of::<u32>();
        assert!(
            source.len() % SPIRV_WORD_LEN == 0,
            "spirv bytecode not a whole number of 32-bit words"
        );

        let module_bytecode: &[u32] = unsafe {
            slice::from_raw_parts(source.as_ptr() as *const _, source.len() / SPIRV_WORD_LEN)
        };

        WebGpuShader {
            name: if cfg!(debug_assertions) {
                Some(name.to_owned())
            } else {
                None
            },
            kind,
            shader_vertex_attributes,
            module: self.device.create_shader_module(module_bytecode),
        }
    }

    fn create_vertex_array(&self) -> Self::VertexArray {
        // self.device.create_buffer(&wgpu::BufferDescriptor{ label: None, size: (), usage: ()});

        WebGpuVertexArray {
            vertex_buffers: RefCell::new(Vec::new()),
            index_buffer: RefCell::new(None),
        }
    }

    fn create_program_from_shaders(
        &self,
        _resources: &dyn ResourceLoader,
        name: &str,
        shaders: ProgramKind<Self::Shader>,
    ) -> Self::Program {
        // WebGPU's program is part of the render pipeline, which includes all GPU state, so we defer creating it until we know our state??
        match shaders {
            ProgramKind::Raster { vertex, fragment } => WebGpuProgram {
                name: if cfg!(debug_assertions) {
                    Some(name.to_owned())
                } else {
                    None
                },
                vertex_shader: vertex,
                fragment_shader: fragment,
            },
            ProgramKind::Compute(shader) => todo!(),
        }
    }

    fn set_compute_program_local_size(
        &self,
        program: &mut Self::Program,
        local_size: ComputeDimensions,
    ) {
        todo!()
    }

    fn get_vertex_attr(&self, program: &Self::Program, name: &str) -> Option<Self::VertexAttr> {
        dbg!(name, &program.vertex_shader.shader_vertex_attributes);
        program
            .vertex_shader
            .shader_vertex_attributes
            .as_ref()
            .expect("vertex shader must have attribute table")
            .get(name)
            .map(|bind_location| WebGpuVertexAttr {
                name: name.to_owned(),
                bind_location: *bind_location,
            })
    }

    fn get_uniform(&self, program: &Self::Program, name: &str) -> Self::Uniform {
        // TODO check for validity in program? why is program passed?
        WebGpuUniform {
            name: name.to_owned(),
        }
    }

    fn get_texture_parameter(&self, program: &Self::Program, name: &str) -> Self::TextureParameter {
        dbg!(program);
        dbg!(name);
        todo!()
    }

    fn get_image_parameter(&self, program: &Self::Program, name: &str) -> Self::ImageParameter {
        todo!()
    }

    fn get_storage_buffer(
        &self,
        program: &Self::Program,
        name: &str,
        binding: u32,
    ) -> Self::StorageBuffer {
        todo!()
    }

    fn bind_buffer(
        &self,
        vertex_array: &Self::VertexArray,
        buffer: &Self::Buffer,
        target: BufferTarget,
    ) {
        match target {
            BufferTarget::Vertex => vertex_array.vertex_buffers.borrow_mut().push(VertexBuffer {
                buffer: buffer.clone(),
                stride: 0, // unknown
                step_mode: wgpu::InputStepMode::Vertex,
                descriptor: Vec::new(),
            }),
            BufferTarget::Index => *vertex_array.index_buffer.borrow_mut() = Some(buffer.clone()),
            BufferTarget::Storage => {
                // TODO
            }
        }
    }

    fn configure_vertex_attr(
        &self,
        vertex_array: &Self::VertexArray,
        attr: &Self::VertexAttr,
        descriptor: &VertexAttrDescriptor,
    ) {
        let mut vertex_buffer =
            std::cell::RefMut::map(vertex_array.vertex_buffers.borrow_mut(), |r| {
                r.get_mut(descriptor.buffer_index as usize)
                    .expect("configuring a vertex attribute for an unbound buffer?")
            });

        vertex_buffer.stride = descriptor.stride as u64;
        vertex_buffer.step_mode = match descriptor.divisor {
            0 => wgpu::InputStepMode::Vertex,
            1 => wgpu::InputStepMode::Instance,
            _ => panic!(),
        };
        vertex_buffer
            .descriptor
            .push(wgpu::VertexAttributeDescriptor {
                offset: descriptor.offset as u64,
                format: {
                    use wgpu::VertexFormat as Format;
                    use VertexAttrClass as Class;
                    use VertexAttrType as Type;

                    // TODO waste the second half of unsupported attribute types? or just let them overlap and be unsafe in shaders?
                    match (descriptor.class, descriptor.attr_type, descriptor.size) {
                        (Class::Int, Type::I8, 1) => Format::Char2, // TODO: format unsupported by WebGPU
                        (Class::Int, Type::I8, 2) => Format::Char2,
                        (Class::Int, Type::I8, 3) => Format::Char4, // TODO: format unsupported by WebGPU
                        (Class::Int, Type::I8, 4) => Format::Char4,
                        (Class::Int, Type::U8, 1) => Format::Uchar2, // TODO: format unsupported by WebGPU
                        (Class::Int, Type::U8, 2) => Format::Uchar2,
                        (Class::Int, Type::U8, 3) => Format::Uchar4, // TODO: format unsupported by WebGPU
                        (Class::Int, Type::U8, 4) => Format::Uchar4,
                        (Class::FloatNorm, Type::U8, 1) => Format::Uchar2Norm, // TODO: format unsupported by WebGPU
                        (Class::FloatNorm, Type::U8, 2) => Format::Uchar2Norm,
                        (Class::FloatNorm, Type::U8, 3) => Format::Uchar4Norm, // TODO: format unsupported by WebGPU
                        (Class::FloatNorm, Type::U8, 4) => Format::Uchar4Norm,
                        (Class::FloatNorm, Type::I8, 1) => Format::Char2Norm, // TODO: format unsupported by WebGPU
                        (Class::FloatNorm, Type::I8, 2) => Format::Char2Norm,
                        (Class::FloatNorm, Type::I8, 3) => Format::Char4Norm, // TODO: format unsupported by WebGPU
                        (Class::FloatNorm, Type::I8, 4) => Format::Char4Norm,
                        (Class::Int, Type::I16, 1) => Format::Short2, // TODO: format unsupported by WebGPU
                        (Class::Int, Type::I16, 2) => Format::Short2,
                        (Class::Int, Type::I16, 3) => Format::Short4, // TODO: format unsupported by WebGPU
                        (Class::Int, Type::I16, 4) => Format::Short4,
                        (Class::Int, Type::U16, 1) => Format::Ushort2, // TODO: format unsupported by WebGPU
                        (Class::Int, Type::U16, 2) => Format::Ushort2,
                        (Class::Int, Type::U16, 3) => Format::Ushort4, // TODO: format unsupported by WebGPU
                        (Class::Int, Type::U16, 4) => Format::Ushort4,
                        (Class::FloatNorm, Type::U16, 1) => Format::Ushort2Norm, // TODO: format unsupported by WebGPU
                        (Class::FloatNorm, Type::U16, 2) => Format::Ushort2Norm,
                        (Class::FloatNorm, Type::U16, 3) => Format::Ushort4Norm, // TODO: format unsupported by WebGPU
                        (Class::FloatNorm, Type::U16, 4) => Format::Ushort4Norm,
                        (Class::FloatNorm, Type::I16, 1) => Format::Short2Norm, // TODO: format unsupported by WebGPU
                        (Class::FloatNorm, Type::I16, 2) => Format::Short2Norm,
                        (Class::FloatNorm, Type::I16, 3) => Format::Short4Norm, // TODO: format unsupported by WebGPU
                        (Class::FloatNorm, Type::I16, 4) => Format::Short4Norm,
                        (Class::Float, Type::F32, 1) => Format::Float,
                        (Class::Float, Type::F32, 2) => Format::Float2,
                        (Class::Float, Type::F32, 3) => Format::Float3,
                        (Class::Float, Type::F32, 4) => Format::Float4,
                        (attr_class, attr_type, attr_size) => panic!(
                            "Unsupported vertex class/type/size combination: {:?}/{:?}/{}!",
                            attr_class, attr_type, attr_size
                        ),
                    }
                },
                shader_location: attr.bind_location,
            });
    }

    fn create_framebuffer(&self, texture: Self::Texture) -> Self::Framebuffer {
        WebGpuFramebuffer(texture)
    }

    fn create_buffer(&self, mode: BufferUploadMode) -> Self::Buffer {
        WebGpuBuffer {
            inner: LazilyInitialized::uninitialized(),
        }
    }

    fn allocate_buffer<T>(&self, buffer: &Self::Buffer, data: BufferData<T>, target: BufferTarget) {
        // assert_eq!(
        //     *buffer,
        //     WebGpuBuffer::Uninitialized,
        //     "tried to initialized an already initialized buffer"
        // );

        // TODO use mode?

        // TODO probably not a good idea to have both src and dst?
        let usage = match target {
            BufferTarget::Vertex => {
                wgpu::BufferUsage::VERTEX
                    | wgpu::BufferUsage::COPY_SRC
                    | wgpu::BufferUsage::COPY_DST
            }
            BufferTarget::Index => {
                wgpu::BufferUsage::INDEX | wgpu::BufferUsage::COPY_SRC | wgpu::BufferUsage::COPY_DST
            }
            BufferTarget::Storage => {
                wgpu::BufferUsage::STORAGE
                    | wgpu::BufferUsage::COPY_SRC
                    | wgpu::BufferUsage::COPY_DST
            }
        } | wgpu::BufferUsage::empty();

        let (new_buffer, new_len) = match data {
            BufferData::Uninitialized(size) => (
                self.device.create_buffer(&wgpu::BufferDescriptor {
                    label: None,
                    size: size as u64,
                    usage,
                }),
                size,
            ),
            BufferData::Memory(data) => {
                let data_len_in_bytes = data.len() * mem::size_of::<T>();
                let data =
                    unsafe { slice::from_raw_parts(data.as_ptr() as *const u8, data_len_in_bytes) };
                (
                    self.device.create_buffer_with_data(data, usage),
                    data_len_in_bytes,
                )
            }
        };

        buffer
            .inner
            .initialize_or_replace_with(Rc::new(BufferStorage {
                buffer: new_buffer,
                size: new_len,
            }));

        // TODO should we reuse old buffer?
        // let mut old_inner = buffer.inner.borrow_mut();
        // if let BufferStorage::Allocated { buffer, size } = &*old_inner {
        //     let mut encoder = self.borrow_current_command_encoder();
        //     // TODO mismatched size?
        //     if *size <= new_len {
        //         // if len == *size {
        //         encoder.copy_buffer_to_buffer(&new_buffer, 0, buffer, 0, new_len as u64);
        //     } else {
        //         *old_inner = BufferStorage::Allocated {
        //             buffer: Rc::new(new_buffer),
        //             size: new_len,
        //         };
        //     }
        // } else {
        //     *old_inner = BufferStorage::Allocated {
        //         buffer: Rc::new(new_buffer),
        //         size: new_len,
        //     };
        // }
    }

    fn upload_to_buffer<T>(
        &self,
        buffer: &Self::Buffer,
        position: usize,
        data: &[T],
        target: BufferTarget,
    ) {
        todo!()
    }

    fn framebuffer_texture<'f>(&self, framebuffer: &'f Self::Framebuffer) -> &'f Self::Texture {
        &framebuffer.0
    }

    fn destroy_framebuffer(&self, framebuffer: Self::Framebuffer) -> Self::Texture {
        todo!()
    }

    fn texture_format(&self, texture: &Self::Texture) -> TextureFormat {
        texture.format
    }

    fn texture_size(&self, texture: &Self::Texture) -> Vector2I {
        texture.size
    }

    fn set_texture_sampling_mode(&self, texture: &Self::Texture, flags: TextureSamplingFlags) {
        texture.sampling_flags.set(flags);
    }

    /// Upload `data` to a buffer and copy to texture in a new command buffer.
    fn upload_to_texture(&self, texture: &Self::Texture, rect: RectI, data: TextureDataRef) {
        /// Hack to avoid a dependency on the `half` crate.
        #[allow(non_camel_case_types)]
        type f16 = u16;

        let data = unsafe {
            let data_ptr = data.check_and_extract_data_ptr(rect.size(), texture.format);
            let data_len = match data {
                TextureDataRef::U8(data) => data.len() * mem::size_of::<u8>(),
                TextureDataRef::F16(data) => data.len() * mem::size_of::<f16>(),
                TextureDataRef::F32(data) => data.len() * mem::size_of::<f32>(),
            };
            slice::from_raw_parts(data_ptr as *const u8, data_len)
        };

        let data_buffer = self
            .device
            .create_buffer_with_data(data, wgpu::BufferUsage::COPY_SRC);

        let mut encoder = self.borrow_current_command_encoder();
        encoder.copy_buffer_to_texture(
            wgpu::BufferCopyView {
                buffer: &data_buffer,
                offset: 0,
                bytes_per_row: {
                    texture.size.x().expect_unsigned()
                        * match texture.format {
                            TextureFormat::R8 => mem::size_of::<u8>(),
                            TextureFormat::R16F => mem::size_of::<f16>(),
                            TextureFormat::RGBA8 => 2 * mem::size_of::<u8>(),
                            TextureFormat::RGBA16F => 4 * mem::size_of::<f16>(),
                            TextureFormat::RGBA32F => 4 * mem::size_of::<f32>(),
                        } as u32
                },
                rows_per_image: texture.size.y().expect_unsigned(),
            },
            wgpu::TextureCopyView {
                texture: &texture.inner,
                mip_level: 1,
                array_layer: 0,
                origin: wgpu::Origin3d::ZERO,
            },
            wgpu::Extent3d {
                width: texture.size.x().expect_unsigned(),
                height: texture.size.y().expect_unsigned(),
                depth: 1,
            },
        );
    }

    fn read_pixels(
        &self,
        target: &RenderTarget<Self>,
        viewport: RectI,
    ) -> Self::TextureDataReceiver {
        todo!()
    }

    fn begin_commands(&self) {
        self.finish_current_command_encoder();

        // assert!(
        //     self.current_command_encoder.borrow().is_none(),
        //     "begin_commands and end_commands must be called in pairs"
        // );
        // *self.current_command_encoder.borrow_mut() = Some(
        //     self.device
        //         .create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None }),
        // );
    }

    fn end_commands(&self) {
        // no-op. see: `Self::finish_current_command_encoder`.

        // self.command_buffers.borrow_mut().push(
        //     self.current_command_encoder
        //         .borrow_mut()
        //         .take()
        //         .expect("begin_commands and end_commands must be called in pairss")
        //         .finish(),
        // );
    }

    fn draw_arrays(&self, index_count: u32, render_state: &RenderState<Self>) {
        todo!()
    }

    fn draw_elements(&self, index_count: u32, render_state: &RenderState<Self>) {
        todo!()
    }

    fn draw_elements_instanced(
        &self,
        index_count: u32,
        instance_count: u32,
        render_state: &RenderState<Self>,
    ) {
        let mut encoder = self.borrow_current_command_encoder();

        // render_pass.set_pipeline(todo!());

        let vertex_buffers: Vec<_> = render_state
            .vertex_array
            .vertex_buffers
            .borrow()
            .iter()
            .map(|buffer| buffer.buffer.inner.assume_init().clone())
            .collect();

        let index_buffer = render_state
            .vertex_array
            .index_buffer
            .borrow()
            .as_ref()
            .expect("index buffer should be bound to vertex array before drawing")
            .inner
            .assume_init()
            .clone();

        let target_view = match render_state.target {
            RenderTarget::Default => todo!(),
            RenderTarget::Framebuffer(framebuffer) => framebuffer.0.inner.create_default_view(),
        };

        let a = render_state.vertex_array.vertex_buffers.borrow().clone();
        let vertex_buffer_descriptors = {
            a.iter()
                .map(|vertex_buffer| wgpu::VertexBufferDescriptor {
                    stride: vertex_buffer.stride,
                    step_mode: wgpu::InputStepMode::Vertex,
                    attributes: &vertex_buffer.descriptor,
                })
                .collect::<Vec<_>>()
        };

        // TODO cache the program. how do we know the render options/vertex layout/bind groups beforehand? just cache after first render?
        let pipeline_layout = self
            .device
            .create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
                bind_group_layouts: &[&self.device.create_bind_group_layout(
                    &wgpu::BindGroupLayoutDescriptor {
                        bindings: &[
                                        // todo
                                        // wgpu::BindGroupLayoutEntry {
                                        //     binding: todo!(),
                                        //     visibility: todo!(),
                                        //     ty: todo!(),
                                        // },
                                    ],
                        label: None,
                    },
                )],
            });

        fn to_wgpu_blend_descriptor(
            src_factor: BlendFactor,
            dest_factor: BlendFactor,
            operation: BlendOp,
        ) -> wgpu::BlendDescriptor {
            fn to_wgpu_blend_factor(blend_factor: BlendFactor) -> wgpu::BlendFactor {
                match blend_factor {
                    BlendFactor::Zero => wgpu::BlendFactor::Zero,
                    BlendFactor::One => wgpu::BlendFactor::One,
                    BlendFactor::SrcAlpha => wgpu::BlendFactor::SrcAlpha,
                    BlendFactor::OneMinusSrcAlpha => wgpu::BlendFactor::OneMinusSrcAlpha,
                    BlendFactor::DestAlpha => wgpu::BlendFactor::DstAlpha,
                    BlendFactor::OneMinusDestAlpha => wgpu::BlendFactor::OneMinusDstAlpha,
                    BlendFactor::DestColor => wgpu::BlendFactor::DstColor,
                }
            }

            wgpu::BlendDescriptor {
                src_factor: to_wgpu_blend_factor(src_factor),
                dst_factor: to_wgpu_blend_factor(dest_factor),
                operation: match operation {
                    BlendOp::Add => wgpu::BlendOperation::Add,
                    BlendOp::Subtract => wgpu::BlendOperation::Subtract,
                    BlendOp::ReverseSubtract => wgpu::BlendOperation::ReverseSubtract,
                    BlendOp::Min => wgpu::BlendOperation::Min,
                    BlendOp::Max => wgpu::BlendOperation::Max,
                },
            }
        }

        dbg!(render_state.program);
        let render_pipeline = self
            .device
            .create_render_pipeline(&wgpu::RenderPipelineDescriptor {
                layout: &pipeline_layout,
                vertex_stage: wgpu::ProgrammableStageDescriptor {
                    module: &render_state.program.vertex_shader.module,
                    entry_point: "main",
                },
                fragment_stage: Some(wgpu::ProgrammableStageDescriptor {
                    module: &render_state.program.fragment_shader.module,
                    entry_point: "main",
                }),
                rasterization_state: Some(wgpu::RasterizationStateDescriptor {
                    front_face: wgpu::FrontFace::Cw,
                    cull_mode: wgpu::CullMode::None, // todo
                    depth_bias: 0,
                    depth_bias_slope_scale: 0.0,
                    depth_bias_clamp: 0.0,
                }),
                primitive_topology: match render_state.primitive {
                    Primitive::Triangles => wgpu::PrimitiveTopology::TriangleList,
                    Primitive::Lines => wgpu::PrimitiveTopology::LineList,
                },
                color_states: &[wgpu::ColorStateDescriptor {
                    format: match render_state.target {
                        RenderTarget::Default => {
                            // TODO is the assumption that the backbuffer is rgba8 okay?
                            wgpu::TextureFormat::Rgba8Unorm
                        }
                        RenderTarget::Framebuffer(framebuffer) => {
                            texture_format_to_wgpu(framebuffer.0.format)
                        }
                    },
                    color_blend: render_state
                        .options
                        .blend
                        .map(|blend_state| {
                            to_wgpu_blend_descriptor(
                                blend_state.src_rgb_factor,
                                blend_state.dest_rgb_factor,
                                blend_state.op,
                            )
                        })
                        .unwrap_or(wgpu::BlendDescriptor::REPLACE),
                    alpha_blend: render_state
                        .options
                        .blend
                        .map(|blend_state| {
                            to_wgpu_blend_descriptor(
                                blend_state.src_alpha_factor,
                                blend_state.dest_alpha_factor,
                                blend_state.op,
                            )
                        })
                        .unwrap_or(wgpu::BlendDescriptor::REPLACE),
                    write_mask: if render_state.options.color_mask {
                        wgpu::ColorWrite::ALL
                    } else {
                        wgpu::ColorWrite::empty()
                    },
                }],
                depth_stencil_state: {
                    if render_state.options.depth.is_some()
                        || render_state.options.stencil.is_some()
                    {
                        let stencil_state_descriptor = render_state
                            .options
                            .stencil
                            .map(|stencil_state| wgpu::StencilStateFaceDescriptor {
                                compare: match stencil_state.func {
                                    StencilFunc::Always => wgpu::CompareFunction::Always,
                                    StencilFunc::Equal => wgpu::CompareFunction::Equal,
                                },
                                fail_op: wgpu::StencilOperation::Keep,
                                depth_fail_op: wgpu::StencilOperation::Keep,
                                pass_op: if stencil_state.write {
                                    wgpu::StencilOperation::Replace
                                } else {
                                    wgpu::StencilOperation::Keep
                                },
                            })
                            .unwrap_or(wgpu::StencilStateFaceDescriptor::IGNORE);

                        Some(wgpu::DepthStencilStateDescriptor {
                            format: wgpu::TextureFormat::Depth24PlusStencil8,
                            depth_write_enabled: render_state
                                .options
                                .depth
                                .map(|depth_state| depth_state.write)
                                .unwrap_or(false),
                            depth_compare: render_state
                                .options
                                .depth
                                .map(|depth_state| match depth_state.func {
                                    DepthFunc::Less => wgpu::CompareFunction::Less,
                                    DepthFunc::Always => wgpu::CompareFunction::Always,
                                })
                                .unwrap_or(wgpu::CompareFunction::Never),
                            stencil_front: stencil_state_descriptor.clone(),
                            stencil_back: stencil_state_descriptor,
                            stencil_read_mask: render_state
                                .options
                                .stencil
                                .map(|stencil_state| stencil_state.reference)
                                .unwrap_or(!0),
                            stencil_write_mask: render_state
                                .options
                                .stencil
                                .map(|stencil_state| stencil_state.mask)
                                .unwrap_or(0),
                        })
                    } else {
                        None
                    }
                },
                vertex_state: wgpu::VertexStateDescriptor {
                    index_format: wgpu::IndexFormat::Uint32,
                    vertex_buffers: &vertex_buffer_descriptors,
                },
                sample_count: 1,
                sample_mask: !0,
                alpha_to_coverage_enabled: false,
            });

        let mut render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
            color_attachments: &[wgpu::RenderPassColorAttachmentDescriptor {
                attachment: &target_view,
                resolve_target: None,
                load_op: if render_state.options.clear_ops.color.is_some() {
                    wgpu::LoadOp::Clear
                } else {
                    wgpu::LoadOp::Load
                },
                store_op: wgpu::StoreOp::Store,
                clear_color: render_state.options.clear_ops.color.map_or(
                    wgpu::Color::TRANSPARENT,
                    |color| wgpu::Color {
                        r: color.r().into(),
                        g: color.g().into(),
                        b: color.b().into(),
                        a: color.a().into(),
                    },
                ),
            }],
            depth_stencil_attachment: if matches!(render_state.target, RenderTarget::Default) {
                Some(wgpu::RenderPassDepthStencilAttachmentDescriptor {
                    attachment: &self.main_depth_stencil_texture_view,
                    depth_load_op: if render_state.options.clear_ops.depth.is_some() {
                        wgpu::LoadOp::Clear
                    } else {
                        wgpu::LoadOp::Load
                    },
                    depth_store_op: wgpu::StoreOp::Store,
                    clear_depth: render_state.options.clear_ops.depth.unwrap_or(0.0),
                    stencil_load_op: if render_state.options.clear_ops.stencil.is_some() {
                        wgpu::LoadOp::Clear
                    } else {
                        wgpu::LoadOp::Load
                    },
                    stencil_store_op: wgpu::StoreOp::Store,
                    clear_stencil: render_state.options.clear_ops.stencil.unwrap_or(0).into(),
                })
            } else {
                None
            },
        });

        render_pass.set_pipeline(&render_pipeline);

        render_pass.set_viewport(
            render_state.viewport.origin_x() as f32,
            render_state.viewport.origin_y() as f32,
            render_state.viewport.width() as f32,
            render_state.viewport.height() as f32,
            0.0,
            1.0,
        );
        // render_pass.set_bind_group(index, bind_group, offsets);

        for (slot, vertex_buffer) in vertex_buffers.iter().enumerate() {
            render_pass.set_vertex_buffer(
                slot as u32,
                &vertex_buffer.buffer,
                0,
                vertex_buffer.size as u64,
            );
        }

        render_pass.set_index_buffer(&index_buffer.buffer, 0, index_buffer.size as u64);
        render_pass.draw_indexed(0..index_count, 0, 0..instance_count);
    }

    fn dispatch_compute(&self, dimensions: ComputeDimensions, state: &ComputeState<Self>) {
        todo!()
    }

    fn add_fence(&self) -> Self::Fence {
        todo!()
    }

    fn wait_for_fence(&self, fence: &Self::Fence) {
        todo!()
    }

    fn create_timer_query(&self) -> Self::TimerQuery {
        WebGpuTimerQuery {}
    }

    fn begin_timer_query(&self, query: &Self::TimerQuery) {
        todo!()
    }

    fn end_timer_query(&self, query: &Self::TimerQuery) {
        todo!()
    }

    fn try_recv_timer_query(&self, query: &Self::TimerQuery) -> Option<Duration> {
        todo!()
    }

    fn recv_timer_query(&self, query: &Self::TimerQuery) -> Duration {
        todo!()
    }

    fn try_recv_texture_data(&self, receiver: &Self::TextureDataReceiver) -> Option<TextureData> {
        todo!()
    }

    fn recv_texture_data(&self, receiver: &Self::TextureDataReceiver) -> TextureData {
        todo!()
    }
}
