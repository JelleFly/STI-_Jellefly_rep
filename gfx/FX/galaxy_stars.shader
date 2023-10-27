Includes = {
	"terra_incognita.fxh"
}

PixelShader =
{
	Samplers = 
	{
		DiffuseTexture = 
		{
			Index = 0;
			MagFilter = "Linear";
			MinFilter = "Linear";
			AddressU = "Wrap";
			AddressV = "Wrap";
		}
		
		TerraIncognitaTexture = 
		{
			Index = 1;
			MagFilter = "Linear";
			MinFilter = "Linear";
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
	}
}

VertexStruct VS_INPUT
{
    float2 vPosition  		: POSITION;
	float2 vUV				: TEXCOORD0;
	float3 vPos				: TEXCOORD1;
};

VertexStruct VS_OUTPUT
{
    float4 vPosition 		: PDX_POSITION;
    float2 vUV				: TEXCOORD0;
	float4 vPos				: TEXCOORD1;
};

ConstantBuffer( Common, 0, 0 )
{
	float4x4 	ViewProjectionMatrix;
	float4		Right;
	float4		Up;
	float 		Scale;
};

VertexShader =
{
	MainCode VertexShader
		ConstantBuffers = { Common }
	[[
		VS_OUTPUT main(const VS_INPUT In )
		{
			VS_OUTPUT Out;

			float4 vPos 		= float4( In.vPos.xyz, 1.0 ); 
			float3 vOffset 		= In.vPosition.x * ( Right.xyz + In.vPosition.y * Up.xyz ) * Scale * 1.5; //Billboard	
			vPos.xyz 			+= float3( vOffset.x, vOffset.y, vOffset.z );

			Out.vPos			= vPos;
			Out.vPosition		= mul( ViewProjectionMatrix, vPos );
			Out.vUV				= In.vUV;
			return Out;
		}
		
	]]
}

PixelShader =
{
	MainCode PixelShader
	[[
		float4 main( VS_OUTPUT In ) : PDX_COLOR
		{
			float4 vColor = tex2D( DiffuseTexture, In.vUV );
			vColor = ApplyTerraIncognita( vColor, In.vPos.xz, 1.0f, TerraIncognitaTexture );
			return vColor*0.85f;
		}
		
	]]
}

DepthStencilState DepthStencilState
{
	DepthEnable = no
}

BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "ONE"
	WriteMask = "RED|GREEN|BLUE"
}

RasterizerState RasterizerState
{
	FillMode = "FILL_SOLID"
	CullMode = "CULL_NONE"
	FrontCCW = no
}


Effect GalaxyStars
{
	VertexShader = "VertexShader";
	PixelShader = "PixelShader";
}