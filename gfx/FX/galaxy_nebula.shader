Includes = {
	"terra_incognita.fxh"
}

PixelShader =
{
	Samplers = 
	{
		NebulaTexture = 
		{
			Index = 0;
			MagFilter = "Linear";
			MinFilter = "Linear";
			AddressU = "Wrap";
			AddressV = "Wrap";
		}
		
		ColorTexture = 
		{
			Index = 1;
			MagFilter = "Linear";
			MinFilter = "Linear";
			AddressU = "Wrap";
			AddressV = "Wrap";
		}	
		
		TerraIncognitaTexture = 
		{
			Index = 2;
			MagFilter = "Linear";
			MinFilter = "Linear";
			AddressU = "Clamp"
			AddressV = "Clamp"
		}

		Border = {
			Index = 3;
			MagFilter = "Linear";
			MinFilter = "Linear";
			MipFilter = "none";
			AddressU = "Wrap";
			AddressV = "Wrap";
		}

		HazardsTexture = {
			Index = 4;
			MagFilter = "Linear";
			MinFilter = "Linear";
			MipFilter = "none";
			AddressU = "Wrap";
			AddressV = "Wrap";
		}

		WarpTexture = {
			Index = 5;
			MagFilter = "Linear";
			MinFilter = "Linear";
			MipFilter = "none";
			AddressU = "Wrap";
			AddressV = "Wrap";
		}
	}
}

VertexStruct VS_INPUT
{
    float2 vPosition  		: POSITION;
	float2 vUV				: TEXCOORD0;
	float3 vPos				: TEXCOORD1;
	float2 vSize_vRot		: TEXCOORD2;
};

VertexStruct VS_OUTPUT
{
    float4 vPosition 	: PDX_POSITION;
	float2 vUV			: TEXCOORD0;
	float2 vPos			: TEXCOORD1;
	float4 vScreenCoord : TEXCOORD2;
};

ConstantBuffer( Common, 0, 0 )
{
	float4x4 	ViewProjectionMatrix;
	float4		TimeRot;
};

VertexShader =
{
	MainCode VertexShader
		ConstantBuffers = { Common }
	[[
		VS_OUTPUT main(const VS_INPUT v )
		{
			VS_OUTPUT Out;
			float4 vPos = float4( v.vPosition.x, -9.0f, v.vPosition.y, 1.0f );	
			vPos.xz *= v.vSize_vRot.x;
			float vTimeRot = TimeRot.x * ( -saturate( -v.vSize_vRot.y * 1000.0f ) + saturate( v.vSize_vRot.y * 1000.0f ) );
			float randSin = sin( v.vSize_vRot.y + vTimeRot );
			float randCos = cos( v.vSize_vRot.y + vTimeRot );
			
			vPos.xz = float2( 
				vPos.x * randCos - vPos.z * randSin, 
				vPos.x * randSin + vPos.z * randCos );		
			
			vPos.xyz += v.vPos;
			vPos.y += ( v.vPosition.x + v.vPosition.y ) * 0.5f * 1.0f;
			
			Out.vPosition  	= mul( ViewProjectionMatrix, vPos );
			Out.vUV			= v.vUV;
			Out.vPos		= vPos.xz;

			Out.vScreenCoord.x = ( Out.vPosition.x * 0.5 + Out.vPosition.w * 0.5 );
			Out.vScreenCoord.y = ( Out.vPosition.w * 0.5 - Out.vPosition.y * 0.5 );
		#ifdef PDX_OPENGL
			Out.vScreenCoord.y = -Out.vScreenCoord.y;
		#endif	
			Out.vScreenCoord.z = Out.vPosition.w;
			Out.vScreenCoord.w = Out.vPosition.w;	

			return Out;
		}
		
	]]
}

PixelShader =
{
	MainCode PixelShader
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			float4 vDiffuse = tex2D( NebulaTexture, v.vUV );
			vDiffuse.a = saturate( vDiffuse.a * 2.0f );
			float4 vColor = tex2D( ColorTexture, v.vUV  );

			float vTI = CalcTerraIncognitaValue( v.vPos.xy, TerraIncognitaTexture );
			
			float4 vBorderColor = tex2Dproj( Border, v.vScreenCoord );
			float4 vHazardsColor = tex2Dproj( HazardsTexture, v.vScreenCoord ); // HRB
			float4 vWarpColor = tex2Dproj( WarpTexture, v.vScreenCoord ); // HRB
			
			vBorderColor.a = saturate( vBorderColor.a * 1.0f );						// Changes nebula color to same color as country border, country border defines country color and border color
			vHazardsColor.a = saturate( vHazardsColor.a * 0.5f ); // HRB
			vWarpColor.a = saturate( vWarpColor.a * 0.5f ); // HRB

			vColor.rgb = lerp( vColor.rgb, vBorderColor.rgb * .0f, vBorderColor.a );
			vColor.rgb = lerp( vColor.rgb, vHazardsColor.rgb * 2.0f, vHazardsColor.a ); // HRB
			vColor.rgb = lerp( vColor.rgb, vWarpColor.rgb * 2.0f, vWarpColor.a ); // HRB

			float4 vTIColor = ApplyTerraIncognitaValue( vColor, TI_GRAY_BRIGHTNESS, vTI );

			float vBorderTI = 0.8f; // Saturate border under TI
			float vHazardsTI = 0.8f; // HRB: Saturate hazards under TI
			float vWarpTI = 0.8f; // HRB: Saturate hazards under TI

			vTI = saturate( vTI + ( vBorderColor.a * vBorderTI ) + ( vHazardsColor.a * vHazardsTI ) + ( vWarpColor.a * vWarpTI ) * saturate( ( 1.0f - vTI ) * 1000 ) );
			vColor = vDiffuse * lerp( vColor, vTIColor + vBorderColor.a * 0.6f + vHazardsColor.a * 0.3f + vWarpColor.a * 0.3, 1.0f - vTI );

			return vColor *1.3f;
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
	AlphaTest = no
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
}

RasterizerState RasterizerState
{
	FillMode = "FILL_SOLID"
	CullMode = "CULL_NONE"
	FrontCCW = no
}


Effect GalaxyNebula
{
	VertexShader = "VertexShader";
	PixelShader = "PixelShader";
}