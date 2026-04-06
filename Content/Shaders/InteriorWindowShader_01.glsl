#---FRAGMENT---#
#include "shaders/template_perframe.glinc"
#include "shaders/template_matrixhelpers.glinc"
#include "shaders/template_lighting_fs.glinc"				#only:LIT
#include "shaders/template_noiseFromTexture.glinc"

uniform vec4 power;
uniform sampler2D tex0; // name: texDiffuse
uniform sampler2D tex1; // name: texTangentNormal			#only:HAS_TNORMALMAP
uniform sampler2D tex1; // name: texWorldNormal				#only:HAS_WNORMALMAP
uniform mat4 world;														#only:HAS_WNORMALMAP
uniform samplerCube tex8; // name: texCube0					#only:HAS_ENVIRONMENTMAP
uniform vec4 environmentSettings;									#only:HAS_ENVIRONMENTMAP

in vec4 UV0;

in vec4 VSOutTEXCOORD0; // name: OutTexCoord0
in vec3 VSOutTEXCOORD1; // name: OutWorldPosition
in vec3 VSOutTEXCOORD2; // name: OutNormal
in vec3 VSOutTEXCOORD3; // name: OutTangent					#only:HAS_TNORMALMAP
in vec3 VSOutTEXCOORD4; // name: OutBitangent				#only:HAS_TNORMALMAP

in vec4 VSOutWORLDCOORD;


out vec4 FragmentColor0; // name: FragmentColor

vec4 hexagon( vec2 p ) 
{
	vec2 q = vec2( p.x*2.0*0.5773503, p.y + p.x*0.5773503 );
	
	vec2 pi = floor(q);
	vec2 pf = fract(q);

	float v = mod(pi.x + pi.y, 3.0);

	float ca = step(1.0,v);
	float cb = step(2.0,v);
	vec2  ma = step(pf.xy,pf.yx);
	
    // distance to borders
	float e = dot( ma, 1.0-pf.yx + ca*(pf.x+pf.y-1.0) + cb*(pf.yx-2.0*pf.xy) );
		
	return vec4( pi + ca - cb*ma, e, 1.0);
}

float edgeBand(float x, float start0, float start1, float end0, float end1)
{
	return smoothstep(start0, start1, x) * (1.0 - smoothstep(end0, end1, x));
}

void main() 
{
	vec2 uv = UV0.xy;
	
	float opacity =power.x;
	vec3 viewDir = normalize(GetTranslation(inverseView)-VSOutTEXCOORD1);
     	 
	// hexagon size
    vec4 h = hexagon(128.0*uv);
    vec3 col = vec3(1.0);
	
	vec3 tot = vec3(1.0);

	int AA = 2;
	    for( int mm=0; mm<AA; mm++ )
    for( int nn=0; nn<AA; nn++ )
    {
		vec3 intcol = vec3(1.0); 
        intcol *= smoothstep( 0.05, 0.25, h.z );
		intcol *= 0.8 + h.z * 0.05;

        tot += intcol;
	}
	tot /= float(AA*AA);

#ifdef HAS_TNORMALMAP
	vec4 normalSample = vec4(mix(vec3(0.70), tot, 0.45), 1.0);
	vec3 tangentSpaceNormal = normalize(vec3((normalSample.xy - 0.5) * 0.55, 1.0));

	mat3 tangentToWorldMatrix = mat3(VSOutTEXCOORD3, VSOutTEXCOORD4, VSOutTEXCOORD2);
	vec3 normal = ( tangentToWorldMatrix* tangentSpaceNormal);
#else 
	vec3 normal = VSOutTEXCOORD2;																	//#only:~HAS_WNORMALMAP
#endif

	float noise = tx_noise(vec3(h.xyz), tex0);
	float mask = smoothstep(opacity - 0.002, opacity + 0.002, noise);
	col *= mask;

	vec3 reflectionA = texture(tex8, -reflect(viewDir, normal).xzy).xyz;
	vec3 reflectionB = texture(tex8, -reflect(viewDir, normalize(mix(normal, VSOutTEXCOORD2, 0.65))).xzy).xyz;
	vec3 reflection = mix(reflectionA, reflectionB, 0.6) * (environmentSettings.x * 0.90);
	vec3 flatReflection = texture(tex8, -reflect(viewDir, normalize(VSOutTEXCOORD2)).xzy).xyz * (environmentSettings.x * 1.00);
	vec3 cellNormalSample = vec3(0.66 + 0.14 * noise, 0.66 + 0.14 * noise, 1.0);
	vec3 cellTangentNormal = normalize(vec3((cellNormalSample.xy - 0.5) * 0.44, 1.0));
	vec3 cellWorldNormal = normalize(tangentToWorldMatrix * cellTangentNormal);
	vec3 cellReflection = texture(tex8, -reflect(viewDir, normalize(mix(cellWorldNormal, VSOutTEXCOORD2, 0.46))).xzy).xyz * (environmentSettings.x * 1.45);
	float flatReflectionGray = mix((flatReflection.x + flatReflection.y + flatReflection.z) / 3.0, max(flatReflection.x, max(flatReflection.y, flatReflection.z)), 0.75);
	float cellReflectionGray = mix((cellReflection.x + cellReflection.y + cellReflection.z) / 3.0, max(cellReflection.x, max(cellReflection.y, cellReflection.z)), 0.80);

	float boundary = 0.165;
	float sd = boundary - h.z;
	float whiteRing = edgeBand(sd, -0.034, -0.022, -0.006, 0.004);
	float blackRing = edgeBand(sd, -0.002, 0.012, 0.044, 0.058);
	float gradientT = clamp((sd - 0.000) / 0.222, 0.0, 1.0);
	float whiteGradient = (1.0 - smoothstep(0.12, 0.80, gradientT)) * smoothstep(0.026, 0.040, sd);

	float interiorMask = step(sd, -0.022);
	float gradientMask = clamp(whiteGradient, 0.0, 1.0);
	float blackMask = clamp(blackRing, 0.0, 1.0);
	float whiteMask = clamp(whiteRing, 0.0, 1.0);

	float interiorGray = mix(flatReflectionGray, cellReflectionGray, 0.82) * 1.05;
	float litResponse = smoothstep(0.10, 0.48, interiorGray);
	float whiteRingResponse = clamp((interiorGray - 0.04) / 0.62, 0.0, 1.0);
	float gradientResponse = smoothstep(0.02, 0.22, interiorGray);
	float whiteRingLevel = mix(0.56, 1.00, whiteRingResponse);
	vec3 interiorColor = vec3(interiorGray * 0.89, interiorGray * 0.95, interiorGray * 1.08);
	vec3 whiteRingColor = vec3(whiteMask * whiteRingLevel);
	vec3 gradientColor = vec3(gradientMask * mix(0.24, 0.46, gradientResponse) * 3.0);
	float coverage = clamp(interiorMask * 0.76 + whiteMask * (0.56 + 0.42 * whiteRingResponse) + gradientMask * (0.28 + 0.26 * gradientResponse), 0.0, 1.0);

	FragmentColor0.xyz = interiorColor * interiorMask;
	FragmentColor0.xyz = mix(FragmentColor0.xyz, vec3(0.0), blackMask);
	FragmentColor0.xyz = mix(FragmentColor0.xyz, gradientColor, gradientMask);
	FragmentColor0.xyz = mix(FragmentColor0.xyz, whiteRingColor, whiteMask);
	FragmentColor0.a = coverage * clamp(col.x + 0.20, 0.0, 0.97);
}

#---VERTEX---#
#include "shaders/template_perframe.glinc"

uniform mat4 world;
uniform mat4 skinmatrix[100];																		#only:SKINNING
#define worldSkin (worldSkinMat)																	#only:SKINNING
#define worldSkin (world)																			#only:~SKINNING
#define worldMatrix (worldSkin)																		#only:~INSTANCED
#define skinMatrix skinmatrix

// in variables
in vec3 POSITION; // name: Pos
in vec4 TEXCOORD0; // name: TexCoord0
in vec3 NORMAL; // name: Normal																		#only:~HAS_WNORMALMAP
in vec3 TANGENT; // name: Tangent																	#only:HAS_TNORMALMAP
in vec3 BITANGENT; // name: Bitangent																#only:HAS_TNORMALMAP
in vec4 BLENDINDICES; // name: BlendIndices															#only:SKINNING
in vec4 BLENDWEIGHT; // name: BlendWeight															#only:SKINNING
in mat4 INSTANCED0; // name: InstanceWorld															#only:INSTANCED
				
// out variables		
out vec4 UV0; // name: OutTexCoord0;		
out vec4 VSOutTEXCOORD0; // name: OutTexCoord0				
out vec3 VSOutTEXCOORD1; // name: OutWorldPosition				
out vec3 VSOutTEXCOORD2; // name: OutNormal															#only:~HAS_WNORMALMAP
out vec3 VSOutTEXCOORD3; // name: OutTangent														#only:HAS_TNORMALMAP
out vec3 VSOutTEXCOORD4; // name: OutBitangent														#only:HAS_TNORMALMAP

out vec4 VSOutWORLDCOORD;

void main()
{
	UV0 = TEXCOORD0;
	
	VSOutTEXCOORD0 = TEXCOORD0;

	mat4 skinMat =	(skinMatrix[int(BLENDINDICES.x)] * BLENDWEIGHT.x) + (skinMatrix[int(BLENDINDICES.y)] * BLENDWEIGHT.y) + #only:SKINNING
					(skinMatrix[int(BLENDINDICES.z)] * BLENDWEIGHT.z) + (skinMatrix[int(BLENDINDICES.w)] * BLENDWEIGHT.w);	#only:SKINNING
	mat4 worldSkinMat = world * skinMat;																					#only:SKINNING

	mat4 worldMatrix = (INSTANCED0 * worldSkin); 													#only:INSTANCED
	
	gl_Position = projectionView * (worldMatrix * vec4(POSITION, 1.0));								#only:~SKYBOX
	
	vec4 worldCoord;
	worldCoord = worldMatrix[2] * vec4(POSITION, 1.0);

	VSOutTEXCOORD1 = (worldMatrix * vec4(POSITION, 1.0)).xyz;
	VSOutTEXCOORD2 = normalize((worldMatrix * vec4(NORMAL , 0.0)).xyz);
#ifdef HAS_TNORMALMAP
	VSOutTEXCOORD3 = normalize((worldMatrix * vec4(TANGENT, 0.0)).xyz);
	VSOutTEXCOORD4 = normalize((worldMatrix * vec4(BITANGENT, 0.0)).xyz);
#endif
	
	
	VSOutWORLDCOORD = worldCoord;
};
