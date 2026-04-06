Material "InteriorWindowDynamicMat_01"
	Order(127);
	Shader "Shaders/InteriorWindowShader_01"
	Texture {"Diffuse","textures/Shaders/256Lut_01.png"}
	Texture {"Tangent Normal Map","Textures/ShipTextures/ExtTextures/ext_BioDome_Normal_01.png"}
	SetLayer { "Default", false }
	ShaderFlag "HAS_TNORMALMAP"
	ShaderFlag "HAS_ENVIRONMENTMAP"
	Texture {"TEXTURE8","textures/CubeMaps/GlassEnvMap_02/cube_BlurredInterior_02.cube"}
	Uniform4f { "environmentSettings", 1.35, 0.0, 0.0, 0.0 }
	Uniform4f { "power", 1.0, 0.0, 0.0, 0.0 }		
	SetLayer { "NoLighting", true }
	RS_BlendMode "AlphaBlend"
	RS_SetFlag { "DepthWrite", false}
	
	

	

