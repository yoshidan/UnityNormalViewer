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
                //Since the line showing the normal display is assumed to be Cube, shift it in the 0.5up direction to make the bottom of the cube the normal position.
                v.vertex += float4(0,0.5,0,1.0);

                //法線表示を示す線をCube想定にしているので、Cubeをup方向に縦長にするためにスケールを調整している
                //Since the line showing the normal display is assumed to be Cube, the scale is adjusted to make Cube vertically long in the up direction.
                const float4 scale = float4(0.005,0.05,0.005,1);
;
                // このメッシュの各頂点のワールド座標に対して法線方向のvectorを追加する
                // Add a normal vector to the world coordinates of each vertex of this mesh
                float4 wpos = mul(m.rotationMatrix, v.vertex * scale) + float4(m.worldVertex.xyz, 1.0);                
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
