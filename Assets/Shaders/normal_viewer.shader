Shader "Custom/normal_viewer"
{
    SubShader
    {
        
        Tags { 
            "Queue"="Transparent"
            "RenderType"="Transparent" 
        }
        LOD 100
        Offset 0, -100
        Blend SrcAlpha OneMinusSrcAlpha
        AlphaToMask On
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag            
            #include "UnityCG.cginc"
            #include "common.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 color: COLOR;
            };

            StructuredBuffer<MeshData> _Buffer;

            v2f vert (appdata v, uint instanceId : SV_InstanceID)
            {
                MeshData m = _Buffer[instanceId] ;
                v2f o;

                //法線表示を示す線をCube想定にしているので、cubeの最下部を法線位置にするため0.5up方向にずらす
                v.vertex += float4(0,0.5,0,1.0);

                //法線表示を示す線をCube想定にしているので、CubeをY軸方向に縦長にするためにスケールを調整している
                const float4 scale = float4(0.005,0.05,0.005,1);
;
                // このメッシュの各頂点のワールド座標に対して法線方向のvectorを追加する
                float4 wpos = mul(m.rotationMatrix, v.vertex * scale) + float4(m.worldVertex.xyz, 1.0);
                
                //法線方向の回転（全頂点に対して一律同じ回転を適用する）
                o.vertex = mul(UNITY_MATRIX_VP, float4(wpos.xyz, 1.0)) ;

                o.color = m.quaternion;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return i.color;
            }
          
            ENDCG
        }
    }
}
