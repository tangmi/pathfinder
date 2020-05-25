fn main() {
    let mut compiler = shaderc::Compiler::new().unwrap();
    let mut options = shaderc::CompileOptions::new().unwrap();
    options.set_include_callback(|include_name, include_type, source_path, include_depth| {
        assert!(matches!(include_type, shaderc::IncludeType::Relative));

        let source_path = std::path::PathBuf::from(source_path);
        let parent_dir = source_path.parent().unwrap();
        let include_path = parent_dir.join(include_name);
        std::fs::read_to_string(&include_path)
            .map_err(|err| format!("{}", err))
            .map(|file| shaderc::ResolvedInclude {
                resolved_name: include_path.to_string_lossy().to_string(),
                content: file,
            })
    });

    let manifest_dir = std::path::PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());
    let shader_dir = manifest_dir.clone();
    let target_dir = manifest_dir
        .parent()
        .unwrap()
        .join("resources")
        .join("shaders");

    for shader_path in std::fs::read_dir(shader_dir)
        .unwrap()
        .filter_map(Result::ok)
        .filter(|entry| {
            if let Some(extension) = entry.path().extension() {
                extension == "glsl"
            } else {
                false
            }
        })
        .map(|entry| entry.path())
    {
        println!("cargo:rerun-if-changed={}", shader_path.display());

        let shader_name = shader_path.file_stem().unwrap();

        let ENTRY_POINT: &str = "main";

        let stage = {
            let filename = shader_path.file_name().unwrap().to_string_lossy();

            if filename.ends_with("vs.glsl") {
                shaderc::ShaderKind::Vertex
            } else if filename.ends_with("fs.glsl") {
                shaderc::ShaderKind::Fragment
            } else if filename.ends_with("cs.glsl") {
                eprintln!("skipping compute shader: {}", shader_path.display());
                continue;
                shaderc::ShaderKind::Compute
            } else if filename.ends_with("inc.glsl") {
                eprintln!("skipping include file: {}", shader_path.display());
                continue;
            } else {
                panic!("unknown shader type! {}", filename)
            }
        };

        let source = std::fs::read_to_string(&shader_path).unwrap();
        let binary_result = match compiler.compile_into_spirv(
            &source,
            stage,
            &shader_path.to_string_lossy(),
            ENTRY_POINT,
            Some(&options),
        ) {
            Ok(binary) => binary,
            Err(err) => {
                eprintln!("{}", err);
                panic!()
            }
        };

        {
            use spirv_cross::spirv;

            // SPIR-V
            {
                std::fs::write(
                    target_dir
                        .join("spirv")
                        .join(format!("{}.spv", shader_name.to_string_lossy())),
                    binary_result.as_binary_u8(),
                )
                .unwrap();
            }

            let module = spirv::Module::from_words(binary_result.as_binary());

            // MSL
            {
                use spirv_cross::msl;

                let mut ast = spirv::Ast::<msl::Target>::parse(&module).unwrap();

                // NOTE this is macOS/v1.2
                ast.set_compiler_options(&msl::CompilerOptions {
                    vertex: msl::CompilerVertexOptions {
                        invert_y: true,
                        ..msl::CompilerVertexOptions::default()
                    },
                    ..msl::CompilerOptions::default()
                })
                .unwrap();

                let shader = ast.compile().unwrap();
                std::fs::write(
                    target_dir
                        .join("metal")
                        .join(format!("{}.metal", shader_name.to_string_lossy())),
                    shader,
                )
                .unwrap();
            }

            // GLSL
            {
                use spirv_cross::glsl;

                let mut ast = spirv::Ast::<glsl::Target>::parse(&module).unwrap();

                for combined_image_sampler in ast.get_combined_image_samplers().unwrap() {
                    let image_name = ast.get_name(combined_image_sampler.image_id).unwrap();
                    let sampler_name = ast.get_name(combined_image_sampler.sampler_id).unwrap();
                    let combined_name_from_sampler_name =
                        &sampler_name[..sampler_name.len() - "Sampler".len()];

                    assert_eq!(
                        &image_name, &combined_name_from_sampler_name,
                        "samplers and textures must be defined in pairs"
                    );

                    ast.set_name(combined_image_sampler.combined_id, &image_name)
                        .unwrap();
                }

                // #version 330
                {
                    ast.set_compiler_options(&glsl::CompilerOptions {
                        version: glsl::Version::V3_30,
                        enable_420_pack_extension: false,
                        vertex: glsl::CompilerVertexOptions::default(),
                    })
                    .unwrap();

                    let shader = ast.compile().unwrap();
                    std::fs::write(
                        target_dir
                            .join("gl3")
                            .join(format!("{}.glsl", shader_name.to_string_lossy())),
                        shader,
                    )
                    .unwrap();
                }

                // #version 430
                {
                    ast.set_compiler_options(&glsl::CompilerOptions {
                        version: glsl::Version::V4_30,
                        enable_420_pack_extension: true,
                        vertex: glsl::CompilerVertexOptions::default(),
                    })
                    .unwrap();

                    let shader = ast.compile().unwrap();
                    std::fs::write(
                        target_dir
                            .join("gl4")
                            .join(format!("{}.glsl", shader_name.to_string_lossy())),
                        shader,
                    )
                    .unwrap();
                }
            }
        }
    }
}
