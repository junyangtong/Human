 //声明参数
			float4 _Tint;
			float _Smoothness;
            sampler2D _MainTex;
            sampler2D _NormalTex;
            sampler2D _Flowmap;
            sampler2D _MixTex;
            float _MetallicInt;
            float4 _MainTex_ST;
			//spec
			float _Specular;
			float _SpecularInt1;
			float _SpecularInt2;
			float _SpecShift1;
			float _SpecShift2;
			float4 _SpecularColor1;
			float4 _SpecularColor2;
			float _Cutoff;
			float _WarpNDL;
			float4 _scatterColor;
			float4 _btdfCol;
			float _btdfpow;
			float _btdfscale;
			float _btdfDistortion;
			////lut
			sampler2D _LUT;

            struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
				float4 tangent  : TANGENT;
            };

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float3 posWS : TEXCOORD2;
				LIGHTING_COORDS(3,4)
				float3 tDirWS : TEXCOORD5;
                float3 bDirWS : TEXCOORD6; 
                float3 nDirWS : TEXCOORD7; 
			};

            v2f vert (appdata v)
            {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.posWS = mul(unity_ObjectToWorld, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.normal = normalize(o.normal);
                o.tDirWS = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );//切线方向
                o.bDirWS = normalize(cross(o.normal, o.tDirWS) * v.tangent.w); //副切线方向
				TRANSFER_VERTEX_TO_FRAGMENT(o)
				return o;
            }
			float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
			{
				return F0 + (max(float3(1.0 - roughness, 1.0 - roughness, 1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
			}
			fixed hairSpecular ( fixed3 T, fixed3 V, fixed3 L, fixed exponent)
			{
				fixed3 H = normalize(L + V);
				fixed dotTH = dot(T, H);
				fixed sinTH = sqrt(1 - dotTH * dotTH);
				fixed dirAtten = smoothstep(-1, 0, dotTH);
				return dirAtten * pow(sinTH, exponent);
			}
								
			//沿着法线方向调整Tangent方向
			fixed3 ShiftTangent ( fixed3 T, fixed3 N, fixed shift)
			{
				return normalize(T + shift * N);
			}
			
            fixed4 frag (v2f i) : SV_Target
            {
				half3 nDirTS = UnpackNormal(tex2D(_Flowmap,i.uv)).rgb;
				half3 nDirTS0 = UnpackNormal(tex2D(_NormalTex,i.uv)).rgb;
                half3x3 TBN = half3x3(i.tDirWS,i.bDirWS,i.normal);//计算TBN矩阵
                half3 nDirWS = normalize(mul(nDirTS0,TBN));
				half3 hight = normalize(nDirWS);
				//法线
				i.normal = hight;

				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
				float3 lightColor = _LightColor0.rgb;
				float3 halfVector = normalize(lightDir + viewDir);  //半角向量
				
				float perceptualRoughness = 1 - _Smoothness;

				float roughness = perceptualRoughness * perceptualRoughness;
				float squareRoughness = roughness * roughness;

				float nl = max(saturate(dot(i.normal, lightDir)), 0.000001);//防止除0
				float nv = max(saturate(dot(i.normal, viewDir)), 0.000001);
				float vh = max(saturate(dot(viewDir, halfVector)), 0.000001);
				float lh = max(saturate(dot(lightDir, halfVector)), 0.000001);
				float nh = max(saturate(dot(i.normal, halfVector)), 0.000001);			
				half halfnl = nl * 0.5 + 0.5;
				//采样MixTex
				fixed4 var_MixTex = tex2D(_MixTex, i.uv);
				half ao = var_MixTex.a;
				//漫反射部分
				float4 var_MainTex = tex2D(_MainTex, i.uv);
                float3 Albedo = _Tint * var_MainTex.rgb;
				half opacity = var_MainTex.a;
				//UnitystandardBRDF.cginc 271行
				//环境光
				float3 ambient = 0.03 * Albedo;
				//菲涅尔F
                float var_Metallic = _MetallicInt;
				float3 F0 = lerp(unity_ColorSpaceDielectricSpec.rgb, Albedo, var_Metallic);
				float3 F = lerp(pow((1 - max(vh, 0)),5), 1, F0);//是hv不是nv
				//镜面反射结果
				float3 kd = (1 - F)*(1 - var_Metallic);//漫反射系数
				// 顽皮狗sss naughty-dog 目的：增加通透感
				half3 diffuse     = saturate(nl + _WarpNDL)/(1 + _WarpNDL); // 0< w <1
				half3 scatterLight     = saturate(_scatterColor + saturate(nl)) * diffuse;
				//Kajiya-Kay模型高光
					//fixed3 spec = tex2D(_AnisoDir, i.uv).rgb;
					//计算切线方向的偏移度
					half shiftTex = var_MixTex.g;
					half3 t1 = ShiftTangent(nDirTS, i.normal, _SpecShift1) ;
					half3 t2 = ShiftTangent(nDirTS, i.normal, _SpecShift2) ;
					//计算高光强度        
					half3 spec1 = hairSpecular(t1, viewDir, lightDir, _SpecularInt1)* _SpecularColor1 * _Specular;
					half3 spec2 = hairSpecular(t2, viewDir, lightDir, _SpecularInt2)* _SpecularColor2 * _Specular;
				//直接光照部分结果
				//float3 specColor = SpecularResult * lightColor * FresnelTerm(1, lh) * UNITY_PI;
				float3 specColor = spec1 + spec2;//var_MixTex.b为噪波
				float3 diffColor = kd * Albedo * lightColor * scatterLight;
				float3 DirectLightResult = diffColor + specColor;

				
				//环境光部分
				half3 ambient_contrib = ShadeSH9(float4(i.normal, 1));
				float3 iblDiffuse = max(half3(0, 0, 0), ambient + ambient_contrib);

				float mip_roughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);//Unity的粗糙度和采样的mipmap等级关系不是线性的，Unity内使用的转换公式为mip = r(1.7 - 0.7r)
				float3 reflectVec = reflect(-viewDir, i.normal);

				half mip = mip_roughness * UNITY_SPECCUBE_LOD_STEPS;//用从0到1之间的mip_roughness函数换算出用于实际采样的mip层级，
				half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectVec, mip); //根据粗糙度生成lod级别对贴图进行三线性采样
				//UNITY_SAMPLE_TEXCUBE_LOD是一个采样函数，粗糙度越高采样出的结果就越模糊。
				float3 iblSpecular = DecodeHDR(rgbm, unity_SpecCube0_HDR);//使用DecodeHDR将颜色从HDR编码下解码
				float2 envBDRF = tex2D(_LUT, float2(lerp(0, 0.99 ,nv), lerp(0, 0.99, roughness))).rg; // LUT采样
				//环境光混合
				float3 Flast = fresnelSchlickRoughness(max(0.0, nv), F0, roughness);//新的菲涅尔系数
				float kdLast = (1 - Flast) * (1 - var_Metallic);
				float3 iblDiffuseResult = iblDiffuse * kdLast * Albedo;
				float3 iblSpecularResult = iblSpecular * (Flast * envBDRF.r + envBDRF.g);
				float3 IndirectResult = iblDiffuseResult + iblSpecularResult;
				IndirectResult *= ao;//环境光遮蔽
				//透射
				float3 H = normalize(lightDir + i.normal * _btdfDistortion);
				float Denl = saturate(dot(viewDir, -H));				
				float btdfmask = pow(Denl*(1-nv), _btdfpow)*_btdfscale;
				half3 btdf = lightColor*btdfmask*_btdfCol*IndirectResult;
				//阴影
				float Shadow = LIGHT_ATTENUATION(i);
				float3 result = DirectLightResult * Shadow + IndirectResult + btdf;
				//透明剪切
				clip(opacity - _Cutoff);
				return float4(result, 1.0);
				//return(1-nv);
            }
