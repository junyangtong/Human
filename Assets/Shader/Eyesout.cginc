
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
				float3 worldPos : TEXCOORD2;
				LIGHTING_COORDS(3,4)
			};

			float4 _Tint;
			float _Smoothness;
            float _MetallicInt;
            float4 _MainTex_ST;
			float _Opacity;
			uniform samplerCUBE _Cubemap;

            v2f vert (appdata v)
            {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.normal = normalize(o.normal);
				TRANSFER_VERTEX_TO_FRAGMENT(o)
				return o;
            }
			float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
			{
				return F0 + (max(float3(1.0 - roughness, 1.0 - roughness, 1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
			}

            fixed4 frag (v2f i) : SV_Target
            {
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				float3 lightColor = _LightColor0.rgb;
				float3 halfVector = normalize(lightDir + viewDir);  //半角向量
				float3 vrDirWS = reflect(-viewDir,i.normal);
				float perceptualRoughness = 1 - _Smoothness;
				float roughness = perceptualRoughness * perceptualRoughness;
				float squareRoughness = roughness * roughness;

				float nl = max(saturate(dot(i.normal, lightDir)), 0.000001);//防止除0
				float nv = max(saturate(dot(i.normal, viewDir)), 0.000001);
				float vh = max(saturate(dot(viewDir, halfVector)), 0.000001);
				float lh = max(saturate(dot(lightDir, halfVector)), 0.000001);
				float nh = max(saturate(dot(i.normal, halfVector)), 0.000001);			

				//漫反射部分
                float3 Albedo = _Tint;
				//环境光
				float3 ambient = 0.03 * Albedo;

				//镜面反射部分
				//D镜面分布函数
				float lerpSquareRoughness = pow(lerp(0.002, 1, roughness), 2);
				float D = lerpSquareRoughness / (pow((pow(nh, 2) * (lerpSquareRoughness - 1) + 1), 2) * UNITY_PI);
				//D*=var_Roughness;
				
				//几何遮蔽G
				float kInDirectLight = pow(squareRoughness + 1, 2) / 8;
				float kInIBL = pow(squareRoughness, 2) / 2;
				float GLeft = nl / lerp(nl, 1, kInDirectLight);
				float GRight = nv / lerp(nv, 1, kInDirectLight);
				float G = GLeft * GRight;

				//菲涅尔F
                float var_Metallic = _MetallicInt;
				//unity_ColorSpaceDielectricSpec.rgb float3(0.04, 0.04, 0.04)
				float3 F0 = lerp(unity_ColorSpaceDielectricSpec.rgb, Albedo, var_Metallic);
				//float3 F = lerp(pow((1 - max(vh, 0)),5), 1, F0);//是hv不是nv
				float3 F = F0 + (1 - F0) * exp2((-5.55473 * vh - 6.98316) * vh);
				//镜面反射结果
				float3 SpecularResult = (D * G * F * 0.25)/(nv * nl);//配平系数=DGF/4×nv×nl
				
				//漫反射系数
				float3 kd = (1 - F)*(1 - var_Metallic);//kd非金属反射系数
				//直接光照部分结果
				float3 specColor = SpecularResult * lightColor * nl * FresnelTerm(1, lh) * UNITY_PI;
				float3 diffColor = kd * Albedo * lightColor * nl;
				float3 DirectLightResult = diffColor + specColor;

				//cubmap
				float4 Cubemap = texCUBElod(_Cubemap,float4(vrDirWS,lerp(0.0,8.0,roughness)));
				half opacity = _Opacity;
				float4 result = float4((DirectLightResult* Cubemap) * opacity, opacity);
				
				return result;
				//return float4(DirectLightResult, 1);
            }
