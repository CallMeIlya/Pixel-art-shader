/*
	MIT Licensed:

	Copyright (c) 2017 Lucas Melo

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"

uniform int ColorsPerChannel < ui_type = "slider";
ui_min = 2; ui_max = 256; > = 16;

uniform int CustomPaletteSize < ui_type = "slider";
ui_min = 2; ui_max = 256; > = 5;

uniform bool CustomPalette < ui_type = "checkbox"; 
> = false;

uniform float DitheringIntensity < ui_type = "slider";
ui_min = 0.0; ui_max = 5.0; > = 0.2;


uniform float SharpnessIntensity < ui_type = "slider";
ui_min = 0.0; ui_max = 5.0; > = 0.4;

uniform int mipLevel = 2;

texture DownsizedBuffer {
	Width = BUFFER_WIDTH/4;    
	Height = BUFFER_HEIGHT/4;
	Format = RGBA8;
};

sampler DownsizedBufferSamp {
	Texture = DownsizedBuffer;
	AddressU = Clamp;
	AddressV = Clamp;
	MipFilter = Point;
	MinFilter = Point;
    MagFilter = Point;
};

texture ColorLUT <source = "MorningBlues5CLUT.png";> {
	Width = 512;
	Height = 128;
};

sampler LUTSampler {
	Texture = ColorLUT;
	AddressU = Clamp;
	AddressV = Clamp;
};



//todo: 
//Implement sharpness

float4 BayerDithering(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target { 
	static const float4x4 bayer4x4 = (1.0/16.0)*float4x4(
		 0.0, 8.0, 2.0,10.0,
		12.0, 4.0,14.0, 6.0,
		 3.0,11.0, 1.0, 9.0,
		15.0, 7.0,13.0, 5.0);
	static const int dimension = 4;
	
	int2 bayerCoordinates = int2((texcoord*float2(BUFFER_WIDTH/4, BUFFER_HEIGHT/4)));
	
	bayerCoordinates[0]%=dimension;
	bayerCoordinates[1]%=dimension;
	
	float bayerValue = bayer4x4[bayerCoordinates[0]][bayerCoordinates[1]] - 0.5;
	
	float3 finalColor = tex2Dlod(ReShade::BackBuffer,float4(texcoord, 0, mipLevel)).rgb+bayerValue*DitheringIntensity;
	
	return float4(finalColor, 1.0);
}

float4 Quantization(float4 vpos: SV_Position, float2 texcoord : TEXCOORD) : SV_Target {	
	float3 pixelColor = tex2Dlod(ReShade::BackBuffer,float4(texcoord, 0, mipLevel)).rgb;
	
	//formula which lowers the number of colors down to ColorsPerChannel or PaletteSize amount
	float3 color;
	if(CustomPalette) {
		color = ((float3)floor(pixelColor*(CustomPaletteSize-1)+0.5))/((float3)(CustomPaletteSize-1));
		color[0] = color[1];
		color[2] = color[1];
	} else {
		color = ((float3)floor(pixelColor*(ColorsPerChannel-1)+0.5))/((float3)(ColorsPerChannel-1));
	}
	
	return float4(color, 1.0);
}

float4 Sharpness(float4 vpos: SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
	float3 OC = tex2D(ReShade::BackBuffer,texcoord - ReShade::PixelSize*float2(1,0)).rgb*SharpnessIntensity*-1;
	float3 CO = tex2D(ReShade::BackBuffer,texcoord - ReShade::PixelSize*float2(0,1)).rgb*SharpnessIntensity*-1;
	
	float3 CC = tex2D(ReShade::BackBuffer,texcoord).rgb*4.0*SharpnessIntensity;
	
	float3 IC = tex2D(ReShade::BackBuffer,texcoord + ReShade::PixelSize*float2(1,0)).rgb * SharpnessIntensity*-1;
	float3 CI = tex2D(ReShade::BackBuffer,texcoord + ReShade::PixelSize*float2(0,1)).rgb * SharpnessIntensity*-1;
	
	return saturate(float4(OC+CO+IC+CI+CC, 1.0));
}

float4 DownsizeIntoBuffer(float4 vpos: SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
	float3 pixelColor = tex2Dlod(ReShade::BackBuffer,float4(texcoord, 0, mipLevel)).rgb;
	return float4(pixelColor, 1.0);
}

float4 ApplyDownsize(float4 vpos: SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
	float2 pixelCoord = texcoord*float2(BUFFER_WIDTH/2.0, BUFFER_HEIGHT/2.0);
	float4 color = float4(tex2Dlod(DownsizedBufferSamp,float4(texcoord, 0, mipLevel)).rgb, 1.0);
	return color;
}

float4 ApplyColorPalette(float4 vpos: SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
	float3 color = tex2Dlod(ReShade::BackBuffer,float4(texcoord, 0, mipLevel)).rgb;
	if(!CustomPalette) {
		return float4(color, 1.0);
	}
	return tex2D(LUTSampler, float2(color[0]+(1.0/512.0), 0.5)); //0.5 just ensures it is in the middle of the LUT and not anywhere else but is largely arbitrary.
	//the offset is to make sure that no color gets picked twice :D
}


// Technique definition
technique PixelartShader {
	/*
	pass {
		PixelShader = Sharpness;
		VertexShader = PostProcessVS;
	}
	*/
	pass {
		RenderTarget = DownsizedBuffer;
		PixelShader = DownsizeIntoBuffer;
		VertexShader = PostProcessVS;
	}
	pass {
		PixelShader = ApplyDownsize;
		VertexShader = PostProcessVS;
	}
	
	
	pass {
		PixelShader = BayerDithering;
		VertexShader = PostProcessVS;
	}
	
	pass {
		PixelShader = Quantization;
		VertexShader = PostProcessVS;
	}
	pass {
		PixelShader = ApplyColorPalette;
		VertexShader = PostProcessVS;
	}


}
