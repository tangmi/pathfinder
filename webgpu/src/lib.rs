use pathfinder_geometry::{rect::RectI, vector::Vector2I};
use pathfinder_gpu::{
    BufferData, BufferTarget, BufferUploadMode, Device, RenderState, RenderTarget, ShaderKind,
    TextureData, TextureDataRef, TextureFormat, TextureSamplingFlags, VertexAttrDescriptor,
};
use pathfinder_resources::ResourceLoader;
use std::cell::RefCell;
use std::time::Duration;

pub struct WebGpuDevice {
    device: wgpu::Device,
    queue: wgpu::Queue,
    current_command_encoder: RefCell<Option<wgpu::CommandEncoder>>,
    command_buffers: RefCell<Vec<wgpu::CommandBuffer>>,
    main_depth_stencil_texture: wgpu::Texture,
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
    pub fn new(window: impl raw_window_handle::HasRawWindowHandle) -> Self {
        futures::executor::block_on(async {
            let (size, surface) = {
                // let size = window.inner_size();
                let size = todo!();
                let surface = wgpu::Surface::create(&window);
                (size, surface)
            };

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
                size: todo!(),
                mip_level_count: todo!(),
                sample_count: todo!(),
                dimension: todo!(),
                format: todo!(),
                usage: todo!(),
            });

            let swap_chain = device.create_swap_chain(
                &surface,
                &wgpu::SwapChainDescriptor {
                    usage: wgpu::TextureUsage::OUTPUT_ATTACHMENT,
                    format: wgpu::TextureFormat::Bgra8Unorm,
                    width: todo!(),
                    height: todo!(),
                    present_mode: wgpu::PresentMode::Fifo,
                },
            );

            WebGpuDevice {
                device,
                queue,
                samplers,
                swap_chain,
                swap_chain_output: swap_chain.get_next_texture().unwrap(),
                command_buffers: RefCell::new(Vec::new()),
                main_depth_stencil_texture,
                current_command_encoder: RefCell::new(None),
            }
        })
    }

    pub fn end_frame(&mut self) {
        self.queue.submit(self.command_buffers.borrow().as_slice());
        self.command_buffers.borrow_mut().clear();
        self.swap_chain_output = self.swap_chain.get_next_texture().unwrap();
    }
}

impl Device for WebGpuDevice {
    type Buffer = ();
    type Framebuffer = ();
    type Program = ();
    type Shader = ();
    type Texture = ();
    type TextureDataReceiver = ();
    type TimerQuery = ();
    type Uniform = ();
    type VertexArray = ();
    type VertexAttr = ();

    fn create_texture(&self, format: TextureFormat, size: Vector2I) -> Self::Texture {
        todo!()
    }

    fn create_texture_from_data(
        &self,
        format: TextureFormat,
        size: Vector2I,
        data: TextureDataRef,
    ) -> Self::Texture {
        todo!()
    }

    fn create_shader(
        &self,
        resources: &dyn ResourceLoader,
        name: &str,
        kind: ShaderKind,
    ) -> Self::Shader {
        todo!()
    }

    fn create_shader_from_source(
        &self,
        name: &str,
        source: &[u8],
        kind: ShaderKind,
    ) -> Self::Shader {
        todo!()
    }

    fn create_vertex_array(&self) -> Self::VertexArray {
        todo!()
    }

    fn create_program_from_shaders(
        &self,
        resources: &dyn ResourceLoader,
        name: &str,
        vertex_shader: Self::Shader,
        fragment_shader: Self::Shader,
    ) -> Self::Program {
        todo!()
    }

    fn get_vertex_attr(&self, program: &Self::Program, name: &str) -> Option<Self::VertexAttr> {
        todo!()
    }

    fn get_uniform(&self, program: &Self::Program, name: &str) -> Self::Uniform {
        todo!()
    }

    fn bind_buffer(
        &self,
        vertex_array: &Self::VertexArray,
        buffer: &Self::Buffer,
        target: BufferTarget,
    ) {
        todo!()
    }

    fn configure_vertex_attr(
        &self,
        vertex_array: &Self::VertexArray,
        attr: &Self::VertexAttr,
        descriptor: &VertexAttrDescriptor,
    ) {
        todo!()
    }

    fn create_framebuffer(&self, texture: Self::Texture) -> Self::Framebuffer {
        todo!()
    }

    fn create_buffer(&self) -> Self::Buffer {
        todo!()
    }

    fn allocate_buffer<T>(
        &self,
        buffer: &Self::Buffer,
        data: BufferData<T>,
        target: BufferTarget,
        mode: BufferUploadMode,
    ) {
        todo!()
    }

    fn framebuffer_texture<'f>(&self, framebuffer: &'f Self::Framebuffer) -> &'f Self::Texture {
        todo!()
    }

    fn destroy_framebuffer(&self, framebuffer: Self::Framebuffer) -> Self::Texture {
        todo!()
    }

    fn texture_format(&self, texture: &Self::Texture) -> TextureFormat {
        todo!()
    }

    fn texture_size(&self, texture: &Self::Texture) -> Vector2I {
        todo!()
    }

    fn set_texture_sampling_mode(&self, texture: &Self::Texture, flags: TextureSamplingFlags) {
        todo!()
    }

    fn upload_to_texture(&self, texture: &Self::Texture, rect: RectI, data: TextureDataRef) {
        todo!()
    }

    fn read_pixels(
        &self,
        target: &RenderTarget<Self>,
        viewport: RectI,
    ) -> Self::TextureDataReceiver {
        todo!()
    }

    fn begin_commands(&self) {
        assert!(
            self.current_command_encoder.borrow().is_none(),
            "begin_commands and end_commands must be called in pairs"
        );
        *self.current_command_encoder.borrow_mut() = Some(
            self.device
                .create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None }),
        );
    }

    fn end_commands(&self) {
        self.command_buffers.borrow_mut().push(
            self.current_command_encoder
                .borrow_mut()
                .take()
                .expect("begin_commands and end_commands must be called in pairss")
                .finish(),
        );
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
        todo!()
    }

    fn create_timer_query(&self) -> Self::TimerQuery {
        todo!()
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
