            //声明参数
			float4 _Tint;
			float4 _btdfCol;
			float _Smoothness;
			float _btdfpow;
			float _btdfscale;
			float _btdfDistortion;
            sampler2D _MainTex;
            sampler2D _NormalTex;
            sampler2D _DepthMap;float4 _DepthMap_TexelSize;
            sampler2D _MixTex;
            sampler2D _beckmannTex;
            float _MetallicInt;
            float _SkinSpecInt1;
            float _SkinSpecInt2;
            float4 _MainTex_ST;
			////lut
			sampler2D _LUT;
			sampler2D _SSSLUT;

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
                o.bDirWS = normalize(cross(o.normal, o.tDirWS) * v.tangent.w);                      //副切线方向
				TRANSFER_VERTEX_TO_FRAGMENT(o)
				return o;
            }
			//计算高度图
			float3 CalculateNormal(float2 uv)
			{
				float2 du = float2(_DepthMap_TexelSize.x * 0.5, 0);
				float u1 = tex2D(_DepthMap, uv - du).r;
				float u2 = tex2D(_DepthMap, uv + du).r;
				float3 tu = float3(1, 0, (u2 - u1) );

				float2 dv = float2(0, _DepthMap_TexelSize.y * 0.5);
				float v1 = tex2D(_DepthMap, uv - dv).r;
				float v2 = tex2D(_DepthMap, uv + dv).r;
				float3 tv = float3(0, 1, (v2 - v1) );

				return normalize(-cross(tv, tu)); //这里加不加负号可以放到高度图的a通道来决定
			}
			float fresnelReflectance( float3 H, float3 V, float F0 ) 
			{   
				float base = 1.0 - dot( V, H );   
				float exponential = pow( base, 5.0 );   
				return exponential + F0 * ( 1.0 - exponential ); 
			}
			float KS_Skin_Specular( 
			float3 N,     // Bumped surface normal    
			float3 L,     // Points to light    
			float3 V,     // Points to eye    
			float m,      // Roughness    
			float rho_s  // Specular brightness    
			) 
			{   
			float result = 0.0;   
			float ndotl = dot( N, L ); 
			if( ndotl > 0.0 ) 
			{    
				float3 h = L + V; // Unnormalized half-way vector    
				float3 H = normalize( h );    
				float ndoth = dot( N, H );    
				float PH = pow( 2.0 *tex2D(_beckmannTex,float2(ndoth,m)), 10.0 );    
				float F = fresnelReflectance( H, V, 0.028 );    
				float frSpec = max( PH * F / dot( h, h ), 0 );    
				result = ndotl * rho_s * frSpec; // BRDF * dot(N,L) * rho_s  
			}  
			return result; 
			}

			float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
			{
				return F0 + (max(float3(1.0 - roughness, 1.0 - roughness, 1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
			}

			half remap(half x, half t1, half t2, half s1, half s2)
			{
				return (x - t1) / (t2 - t1) * (s2 - s1) + s1;
			}
            fixed4 frag (v2f i) : SV_Target
            {
				half3 Detailnormal = CalculateNormal(i.uv);									//细节法线贴图
				half3 nDirTS = UnpackNormal(tex2D(_NormalTex,i.uv)).rgb;
                half3x3 TBN = half3x3(i.tDirWS,i.bDirWS,i.normal);                          //计算TBN矩阵
                half3 nDirWS = normalize(mul(nDirTS,TBN));
                half3 DenDirWS = normalize(mul(Detailnormal,TBN));
				half3 hight = normalize(DenDirWS+nDirWS);
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
				half thickness = var_MixTex.r;
				half curvature = var_MixTex.g;
				half ao = var_MixTex.a;
				//漫反射部分
                float4 var_MainTex = tex2D(_MainTex, i.uv);
				half3 Albedo = _Tint * var_MainTex.rgb;
				half SpecMask = var_MainTex.a;
				//UnitystandardBRDF.cginc 271行
				//环境光
				float3 ambient = 0.03 * Albedo;

				//镜面反射部分
				//D是镜面分布函数，从统计学上估算微平面的取向
				float lerpSquareRoughness = pow(lerp(0.002, 1, roughness), 2);//Unity把roughness lerp到了0.002
				float D = lerpSquareRoughness / (pow((pow(nh, 2) * (lerpSquareRoughness - 1) + 1), 2) * UNITY_PI);
				//D*=var_Roughness;
				
				//几何遮蔽G 高光
				float kInDirectLight = pow(squareRoughness + 1, 2) / 8;
				float kInIBL = pow(squareRoughness, 2) / 2;
				float GLeft = nl / lerp(nl, 1, kInDirectLight);
				float GRight = nv / lerp(nv, 1, kInDirectLight);
				float G = GLeft * GRight;

				//菲涅尔F
                float var_Metallic = _MetallicInt;
				//unity_ColorSpaceDielectricSpec.rgb float3(0.04, 0.04, 0.04)
				float3 F0 = lerp(unity_ColorSpaceDielectricSpec.rgb, Albedo, var_Metallic);
				float3 F = lerp(pow((1 - max(vh, 0)),5), 1, F0);//是hv不是nv
				//float3 F = F0 + (1 - F0) * exp2((-5.55473 * vh - 6.98316) * vh);
				//镜面反射结果
				float3 SpecularResult = (D * G * F * 0.25)/(nv * nl);//配平系数=DGF/4×nv×nl
				
				//漫反射系数
				float3 kd = (1 - var_Metallic);//kd为非金属反射系数，乘上（1-F）是为了保证能量守恒，乘一次(1-var_Metallic)是因为金属会更多的吸收折射光线导致漫反射消失
				//镜面反射方程中的ks就是菲涅尔系数F
				//预积分次表面散射
                fixed3 sss = tex2D(_SSSLUT, float2(halfnl, curvature));
				//透射
				float3 H = normalize(lightDir + i.normal * _btdfDistortion);
				float Denl = pow(saturate(dot(viewDir, -H)), _btdfpow)*_btdfscale;
				half3 btdf =  (Denl+ ambient)*thickness;//_Attenuation * 
				//皮肤高光
				half3 SkinSpec = KS_Skin_Specular(i.normal.xyz,lightDir.xyz,viewDir.xyz,roughness,_SkinSpecInt1) * lightColor ;
				half3 SkinSpec2 = KS_Skin_Specular(i.normal.xyz,lightDir.xyz,viewDir.xyz,roughness-0.5,_SkinSpecInt2) * lightColor ;

				//直接光照部分结果
				float3 specColor = SpecularResult * lightColor * FresnelTerm(1, lh) * UNITY_PI *nl;
				float3 diffColor = kd * Albedo * lightColor;
				half3 spec = SkinSpec2 + SkinSpec + specColor;
				float3 DirectLightResult = diffColor + lerp(spec,0.0,SpecMask);
				DirectLightResult *=sss;

				
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
				half3 aocol = float3(0.0,0.0,0.0);//颜色叠加
				if (ao <=0.5) aocol = 2*Albedo*ao;
				if (ao >0.5) aocol = 1-2*(1-Albedo)*(1-ao);
				//阴影
				float Shadow = LIGHT_ATTENUATION(i);
				Shadow = remap(Shadow, 0, 1.0, 0.7, 1);
				//Shadow = smoothstep(0.1,0.4,Shadow);
				float4 result = float4(DirectLightResult * Shadow + IndirectResult +lightColor*btdf*_btdfCol*IndirectResult , 1);
				return result;
				//return float4(specColor, 1);
            }
