Shader "Unlit/Skybox"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Stars ("_StarsTexture", 2D) = "white" {}
        _Cloud("_CloudTexture", 2D) = "white" {}
        _StarNoise ("_StarNoise", 2D) = "white" {}
        _GalaxyNoiseTex("_GalaxyNoiseTex", 2D) = "white" {}
        _GalaxyTex("_GalaxyTex", 2D) = "white" {}
        [HDR]_GalaxyColor("银河颜色", color)=(0.02202741,0.1479551,0.3113208,1.0)
        [HDR]_GalaxyColor1("银河颜色1", color)=(0.0,0.1603774,0.02672958,1.0)
        _SunRadius("太阳尺寸",float) = 0.12
        [HDR]_SunColor("太阳颜色", color)=(1.735644,0.9867018,1.0,1.0)
        [HDR]_MoonColor("月亮颜色", color)=(4.237095,4.015257,2.772968,1.0)
        _MoonRadius("月亮尺寸",float) = 0.11
        _MoonOffset("月食范围",range(-0.5,0.5)) = -0.01
        _DayBottomColor("白天底颜色", color)=(0.3287202,0.6532937,0.8396226,1.0)
        _DayTopColor("白天顶颜色", color)=(0.6745283,0.8685349,1.0,1.0)
        _NightBottomColor("夜晚底颜色", color)=(0.415064,0.4092204,0.7169812,1.0)
        _NightTopColor("夜晚顶颜色", color)=(0.07591571,0.0,0.509434,1.0)
        _StarsSpeed("_StarsSpeed",float) = 0.01
        _CloudSpeed("_CloudSpeed",float) = 0.36
        _StarsCutoff("_StarsCutoff",float) = 0.9
        _CloudCutoff("_CloudCutoff",float) = 1.84
        [Header(Reflect Setting)]
        _Exponent1("_Exponent1", float) = -0.8
        _Exponent2("_Exponent2", float) = -0.84
        [Header(Suninfluence Setting)]
        _SunInfScale("_SunInfScale", float) = 0.28
        _SunInfColor("_SunInfColor", color)=(1.0,1.0,1.0,1.0)
        _PlanetRadius("_PlanetRadius", float) = 0.5
        _DensityScaleHeight("_DensityScaleHeight", float) = 0.32
        [Header(Cloud Setting)]
        _DistortTex("_DistortTex", 2D) = "white" {}
        _CloudNoise("_CloudNoise", 2D) = "white" {}
        _DistortionSpeed("_DistortionSpeed", float) = 0.28
        _CloudNoiseScale("_CloudNoiseScale", float) = 0.33
        _DistortScale("_DistortScale", float) = 2.06
        _Fuzziness("云层平滑", float) = 0.75
        _FuzzinessSec("云层分层", float) = 1.61
        _CloudNight1("_CloudNight1", color)=(0.1105376,0.1848303,0.3396226,1.0)
        _CloudNight2("_CloudNight2", color)=(0.0,0.0,0.0,1.0)
        _CloudDay1("_CloudDay1", color)=(1.0,1.0,1.0,1.0)
        _CloudDay2("_CloudDay2", color)=(0.0,0.0,0.0,1.0)
        [Header(Cloud Setting)]
        _HorizonIntensity("地平线强度", float) = 7.39
        _HorizonHeight("地平线高度", float) = 0.15
        [HDR]_HorizonColorDay("_HorizonColorDay", color)=(1.74902,2.0,1.482353,1.0)
        [HDR]_HorizonColorNight("_HorizonColorNight", color)=(0.5,0.2193396,0.2193396,1.0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma target 3.0
			#include "Lighting.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
                float3 texcoord : TEXCOORD1;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 posWS  : TEXCOORD1;
                float3 texcoord : TEXCOORD2;
            };

            uniform sampler2D _MainTex;
            uniform sampler2D _Stars;float4 _StarTex_ST;
            uniform sampler2D _Cloud;float4 _CloudTex_ST;
            uniform sampler2D _StarNoise;float4 _StarNoise_ST;
            uniform sampler2D _GalaxyNoiseTex;float4 _GalaxyNoiseTex_ST;
            uniform sampler2D _GalaxyTex;float4 _GalaxyTex_ST;
            uniform float4 _MainTex_ST;
            uniform float4 _GalaxyColor;
            uniform float4 _GalaxyColor1;
            uniform float _SunRadius;
            uniform float4 _SunColor;
            uniform float4 _MoonColor;
            uniform float _MoonRadius;
            uniform float _MoonOffset;
            uniform float4 _DayBottomColor;
            uniform float4 _DayTopColor;
            uniform float4 _NightBottomColor;
            uniform float4 _NightTopColor;
            uniform float _StarsSpeed;
            uniform float _CloudSpeed;
            uniform float _CloudCutoff;
            uniform float _StarsCutoff;
            uniform float _Exponent1;
            uniform float _Exponent2;
            uniform float _SunInfScale;
            uniform float4 _SunInfColor;
            uniform float _PlanetRadius;
            uniform float _DensityScaleHeight;
            uniform float _ExtinctionM;uniform float _ScatteringM;
            uniform sampler2D _DistortTex;
            uniform sampler2D _CloudNoise;
            uniform float _DistortionSpeed;
            uniform float _CloudNoiseScale;
            uniform float _DistortScale;
            uniform float _Fuzziness;
            uniform float _FuzzinessSec;
            uniform float4 _CloudNight1;
            uniform float4 _CloudNight2;
            uniform float4 _CloudDay1;
            uniform float4 _CloudDay2;
            uniform float _HorizonIntensity;
            uniform float _HorizonHeight;
            uniform float4 _HorizonColorDay;
            uniform float4 _HorizonColorNight;

            //星星 
            half4 _StarColor;
            half _StarIntensity;
            half _StarSpeed;
               // 星空散列哈希
                float StarAuroraHash(float3 x) {
                    float3 p = float3(dot(x,float3(214.1 ,127.7,125.4)),
                                dot(x,float3(260.5,183.3,954.2)),
                                dot(x,float3(209.5,571.3,961.2)) );

                    return -0.001 + _StarIntensity*frac(sin(p)*43758.5453123);
                }

                // 星空噪声
                float StarNoise(float3 st){
                    // 卷动星空
                    st += float3(0,_Time.y*_StarSpeed,0);

                    // fbm
                    float3 i = floor(st);
                    float3 f = frac(st);
                
                    float3 u = f*f*(3.0-1.0*f);

                    return lerp(lerp(dot(StarAuroraHash( i + float3(0.0,0.0,0.0)), f - float3(0.0,0.0,0.0) ), 
                                    dot(StarAuroraHash( i + float3(1.0,0.0,0.0)), f - float3(1.0,0.0,0.0) ), u.x),
                                lerp(dot(StarAuroraHash( i + float3(0.0,1.0,0.0)), f - float3(0.0,1.0,0.0) ), 
                                    dot(StarAuroraHash( i + float3(1.0,1.0,0.0)), f - float3(1.0,1.0,0.0) ), u.y), u.z) ;
                }
            // 云散列哈希
                float CloudHash (float2 st) {
                    return frac(sin(dot(st.xy,
                                    float2(12.9898,78.233)))*
                    43758.5453123);
                }

                // 云噪声
                float CloudNoise (float2 st,int flow) {
                    // 云卷动
                    st += float2(0,_Time.y*_CloudSpeed*flow);

                    float2 i = floor(st);
                    float2 f = frac(st);

                    float a = CloudHash(i);
                    float b = CloudHash(i + float2(1.0, 0.0));
                    float c = CloudHash(i + float2(0.0, 1.0));
                    float d = CloudHash(i + float2(1.0, 1.0));

                    float2 u = f * f * (3.0 - 2.0 * f);

                    return lerp(a, b, u.x) +
                            (c - a)* u.y * (1.0 - u.x) +
                            (d - b) * u.x * u.y;
                }

                // 云分型
                float Cloudfbm (float2 st,int flow) {

                    float value = 0.0;
                    float amplitude = .5;
                    float frequency = 0.;

                    for (int i = 0; i < 6; i++) {
                        value += amplitude * CloudNoise(st,flow);
                        st *= 2.;
                        amplitude *= .5;
                    }
                    return value;
                }
                void ComputeOutLocalDensity(float3 position, float3 lightDir, out float localDPA, out float DPC)
                {
                    float3 planetCenter = float3(0,-_PlanetRadius,0);
                    float height = distance(position,planetCenter) - _PlanetRadius;
                    localDPA = exp(-(height/_DensityScaleHeight));

                    DPC = 0;
                    //DPC = ComputeDensityCP(position,lightDir);
                    /*
                    float cosAngle = dot(normalize(position - planetCenter), -lightDir.xyz);
                    DPC = tex2D(_TestTex,float2(cosAngle,height / _AtmosphereHeight)).r;
                    */
                }
                float4 IntegrateInscattering(float3 rayStart,float3 rayDir,float rayLength, float3 lightDir,float sampleCount)
                {
                    float3 stepVector = rayDir * (rayLength / sampleCount);
                    float stepSize = length(stepVector);

                    float scatterMie = 0;

                    float densityCP = 0;
                    float densityPA = 0;
                    float localDPA = 0;

                    float prevLocalDPA = 0;
                    float prevTransmittance = 0;
                    
                    ComputeOutLocalDensity(rayStart,lightDir, localDPA, densityCP);
                    
                    densityPA += localDPA*stepSize;
                    prevLocalDPA = localDPA;

                    float Transmittance = exp(-(densityCP + densityPA)*_ExtinctionM)*localDPA;
                    
                    prevTransmittance = Transmittance;
                    

                    for(float i = 1.0; i < sampleCount; i += 1.0)
                    {
                        float3 P = rayStart + stepVector * i;
                        
                        ComputeOutLocalDensity(P,lightDir,localDPA,densityCP);
                        densityPA += (prevLocalDPA + localDPA) * stepSize/2;

                        Transmittance = exp(-(densityCP + densityPA)*_ExtinctionM)*localDPA;

                        scatterMie += (prevTransmittance + Transmittance) * stepSize/2;
                        
                        prevTransmittance = Transmittance;
                        prevLocalDPA = localDPA;
                    }

                    //scatterMie = scatterMie * MiePhaseFunction(dot(rayDir,-lightDir.xyz));

                    float3 lightInscatter = _ScatteringM*scatterMie;

                    return float4(lightInscatter,1);
                }
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.posWS=mul(unity_ObjectToWorld, v.vertex);//顶点位置OS>WS
                return o;
                o.texcoord = v.texcoord;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                //light坐标系转换矩阵
                //float4x4 LToW = float4x4(_LtoW0,_LtoW1,_LtoW2,_LtoW3);
                //float verticalPos = i.uv.y*0.5 + 0.5;
                //float sunNightStep = smoothstep(-0.3,0.25,_WorldSpaceLightPos0.y);
                //float3 sunUV = mul(i.uv.xyz,LToW);
                float3 sunUV = mul(unity_ObjectToWorld,i.uv.xyz);
                // sun                
                //float3 sunUV = mul(i.uv,UNITY_MATRIX_M);
                float sun = distance(i.uv.xyz, _WorldSpaceLightPos0);
                float sunDisc = 1 - (sun / _SunRadius);
                sunDisc = saturate(sunDisc * 50);
                float3 fallSunColor = _SunColor.rgb*0.4;
                float3 finalSunColor = lerp(fallSunColor,_SunColor.rgb,smoothstep(-0.1,0.1,_WorldSpaceLightPos0.y)) * sunDisc;
                // moon
                float moon = distance(i.uv.xyz, -_WorldSpaceLightPos0); //日月方向相反
                float moonDisc = 1 - (moon / _MoonRadius);
                moonDisc = saturate(moonDisc * 50);

                float crescentMoon = distance(float3(i.uv.x + _MoonOffset, i.uv.yz), -_WorldSpaceLightPos0);
                float crescentMoonDisc = 1 - (crescentMoon / _MoonRadius);
                crescentMoonDisc = saturate(crescentMoonDisc * 50);
                
                //float2 moonUV = sunUV.xy * _MoonTex_ST.xy * (1/_MoonRadius+0.001) + _MoonTex_ST.zw;
                //float4 moonTex = tex2D(_MoonTex, moonUV);
                moonDisc = saturate(moonDisc - crescentMoonDisc);
                float3 fallMoonColor = _MoonColor.rgb*0.4;
                float3 finalMoonColor = lerp(fallMoonColor,_MoonColor.rgb,smoothstep(-0.1,0.1,-_WorldSpaceLightPos0.y)) * moonDisc;

                float3 SunMoon = finalMoonColor + finalSunColor;
                float sunNightStep = saturate(smoothstep(-0.3,0.25,_WorldSpaceLightPos0.y));
                // gradient day sky
                float3 gradientDay = lerp(_DayBottomColor, _DayTopColor, saturate(i.uv.y));
                float3 gradientNight = lerp(_NightBottomColor, _NightTopColor, saturate(i.uv.y));
                float3 skyGradients = lerp(gradientNight, gradientDay,sunNightStep);

                 //GALAXY
                float4 galaxyNoiseTex = tex2D(_GalaxyNoiseTex,(i.uv.xz )*_GalaxyNoiseTex_ST.xy + _GalaxyNoiseTex_ST.zw + float2(_Time.x*0.2,_Time.x*0.2));
                
                float4 galaxy = tex2D(_GalaxyTex,(i.uv.xz + (galaxyNoiseTex-0.5)*0.3)*_GalaxyTex_ST.xy + _GalaxyTex_ST.zw);

                float4 galaxyColor =  (_GalaxyColor * (-galaxy.r+galaxy.g) + _GalaxyColor1*galaxy.g)*smoothstep(-0.1,0.2,1-galaxy.g);

                galaxyNoiseTex = tex2D(_GalaxyNoiseTex,(i.uv.xz )*_GalaxyNoiseTex_ST.xy + _GalaxyNoiseTex_ST.zw - float2(_Time.x*0.2,_Time.x*0.2));
                galaxy = tex2D(_GalaxyTex,(i.uv.xz + (galaxyNoiseTex-0.5)*0.3)*_GalaxyTex_ST.xy + _GalaxyTex_ST.zw);//采样两次noise

                galaxyColor +=  (_GalaxyColor * (-galaxy.r+galaxy.g) + _GalaxyColor1*galaxy.r)*smoothstep(0,0.3,1-galaxy.g);//两次计算color
                //计算星空遮罩
                float p = normalize(i.uv).y;
                float p1 = 1.0f - pow (min (1.0f, 1.0f - p), _Exponent1);
                float p3 = 1.0f - pow (min (1.0f, 1.0f + p), _Exponent2);
                float p2 = 1.0f - p1 - p3;
                float starMask = lerp((1 - smoothstep(-0.4,0.0,1-p2)),0,sunNightStep);
                galaxyColor *= 0.5*starMask;
                
                //Cloud
                    //采样
                    //float2 skyuv = i.posWS.xz*0.1 / clamp(i.posWS.y, 0, 500)*i.posWS.y;
                    float2 skyuv = i.posWS.xz*0.1 / (step(0,i.posWS.y)*i.posWS.y);
                    float3 cloud = tex2D(_Cloud, skyuv + float2(_CloudSpeed, _CloudSpeed) * _Time.x);
                    //cloud = step(_CloudCutoff, cloud);
                    //噪声
                    float distort = tex2D(_DistortTex, (skyuv + (_Time.x * _DistortionSpeed)) * _DistortScale);
                    float noise = tex2D(_CloudNoise, ((skyuv + distort ) - (_Time.x * _CloudSpeed)) * _CloudNoiseScale);
                    float finalNoise = saturate(noise) * 3 * saturate(i.posWS.y);
                    //平滑Cutoff
                    float cloudSec1 = saturate(smoothstep(_CloudCutoff * cloud, _CloudCutoff * cloud + _Fuzziness, finalNoise));
                    //颜色分层
                    float cloudSec2 = saturate(smoothstep(_CloudCutoff * cloud, _CloudCutoff * cloud + _FuzzinessSec, finalNoise));
                    
                    //昼夜颜色变化
                    float3 CloudGradients1 = lerp(_CloudNight1, _CloudDay1,sunNightStep);
                    float3 CloudGradients2 = lerp(_CloudNight2, _CloudDay2,sunNightStep);
                    float3 cloudColin = lerp(0,CloudGradients1,cloudSec2);
                    float3 cloudColout = lerp(0,CloudGradients2,cloudSec1 - cloudSec2);
                    cloud = cloudColin + cloudColout;
                //STAR
                float3 stars = tex2D(_Stars, i.uv.xz*0.6 + float2(_StarsSpeed,_StarsSpeed) * _Time.x);
                float3 starNoiseTex = tex2D(_StarNoise, i.uv.xz + float2(_StarsSpeed,_StarsSpeed) * _Time.y);
                stars = step(_StarsCutoff, stars);
                float starPos = smoothstep(0.21,0.31,stars.r)*starMask;
                float starBright = smoothstep(0.4,0.5,starNoiseTex.r);
                
                float starColor = starPos*starBright;
                starColor = starColor*galaxy.r*0.2 + starColor*(1-galaxy.r)*3;
                starColor *= (1 - cloud);
                 //sunInfluence
                //float sunMask2 = smoothstep(-0.4,0.4,-i.uv.xyz.z) - 0.3;
                //float sunInfScaleMask = smoothstep(-0.01,0.1,_WorldSpaceLightPos0.y) * smoothstep(-0.4,-0.01,-_WorldSpaceLightPos0.y);
                //float3 finalSunInfColor = _SunInfColor * sunMask2 * _SunInfScale * sunInfScaleMask;
                //地平线/模拟大气散射
                float3 horizon = abs((i.uv.y * _HorizonIntensity) - _HorizonHeight);
                float Newp = smoothstep(-0.2,0.2,_WorldSpaceLightPos0.y);
                float3 horizonday = saturate((1 - horizon)) *(lerp(_HorizonColorDay,0,Newp) * Newp);
                float3 horizonnight = -saturate((1 - horizon)) *(lerp(_HorizonColorNight,0,Newp) * Newp);//saturate((1 - horizon)) *lerp(0,_HorizonColorNight,pow (min (1.0f, 1.0f + p), 1)) * saturate(-_WorldSpaceLightPos0.y);
                horizon = horizonday + horizonnight;
                //_HorizonColorNight * saturate(-_WorldSpaceLightPos0.y));

                /*//Mie scattering
                float3 scatteringColor = 0;
                
                float3 rayStart = float3(0,10,0);
                rayStart.y = saturate(rayStart.y);
                float3 rayDir = normalize(i.uv.xyz);

                float3 planetCenter = float3(0, -_PlanetRadius, 0);
                float2 intersection = RaySphereIntersection(rayStart,rayDir,planetCenter,_PlanetRadius + _AtmosphereHeight);
                float rayLength = intersection.y;
                
                intersection = RaySphereIntersection(rayStart, rayDir, planetCenter, _PlanetRadius);
                if (intersection.x > 0)
                    rayLength = min(rayLength, intersection.x*100);

                float4 inscattering = IntegrateInscattering(rayStart, rayDir, rayLength, -_WorldSpaceLightPos0.xyz, 16);
                scatteringColor = _MieColor*_MieStrength * ACESFilm(inscattering);
                //starColor = starColor*galaxy.r*3 + starColor*(1-galaxy.r)*0.3;*/
                 //FINAL
                int reflection = i.uv.y < 0 ? -1 : 1;
                if(reflection == -1){
                    SunMoon = 0;
                }
                float3 finalColor = SunMoon + skyGradients+ (starColor + galaxyColor) + cloud + horizon;//+finalSunInfColor
                // 计算水面反射
                
                if(reflection == -1){
                    // 水面波纹
                    float c = dot(float3(0,1,0),i.uv.xyz);
                    float3 pos = i.uv.xyz * (1.23 / c);
                    float re = Cloudfbm(pos.xz * 0.5,1);

                    finalColor.rgb *= (lerp(0.35,1.12,re) - 0.1) ;
                    float4 reCol = fixed4(finalColor.rgb + re*0.085,re*0.05);
                    finalColor = finalColor*(1 - reCol.a) + reCol * reCol.a;
                    finalColor+= skyGradients * 0.2;

                }

                return float4(finalColor,1.0);
                //return pow (p, 0.2);
            }
            ENDCG
        }
    }
}
