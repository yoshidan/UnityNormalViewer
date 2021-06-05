using System;
using System.Runtime.InteropServices;
using UnityEditor;
using UnityEngine;

public class NormalViewer : MonoBehaviour
{
    private struct MeshData
    {
        public Vector3 vertex;
        public Vector3 normal;
        public Vector3 worldVertex;
        public Matrix4x4 rotationMatrix;
    }
    
    [SerializeField] private ComputeShader computeShader;
    [SerializeField] private Material visibleMaterial;
    [SerializeField] private Mesh visibleMesh;
    [SerializeField] private int visibleMaxCount = 2048;
    private MeshFilter target;
    
    private int visibleCount;
    private static ComputeBuffer computeBuffer;
    private static ComputeBuffer argsBuffer;
    private int kernelId;

    [DrawGizmo(GizmoType.Selected)]
    private static void DrawGizmo(MeshFilter meshFilter, GizmoType type)
    {
        
        var viewer = FindObjectOfType<NormalViewer>();
        if (viewer != null)
        {
            if (meshFilter == viewer.target)
            {
                viewer.Draw();
            }
            else
            {
                viewer.ChangeTarget(meshFilter);
            }
        }
    }

    private void ChangeTarget(MeshFilter target)
    {
        this.target = target;
        var sharedMesh = target.sharedMesh;
        var vertices = sharedMesh.vertices;  
        var normals = sharedMesh.normals;
        var vertexLength = vertices.Length;
        visibleCount = Mathf.Min(visibleMaxCount, vertexLength);
        kernelId = computeShader.FindKernel("NormalMain");
        var datas = new MeshData[visibleCount];
        for (var i = 0; i < visibleCount; i++)
            datas[i] = new MeshData
            {
                vertex = vertices[i % vertices.Length],
                normal = normals[i % vertices.Length],
            };
        computeBuffer?.Release();
        computeBuffer = new ComputeBuffer(visibleCount, Marshal.SizeOf(typeof(MeshData)));
        computeBuffer.SetData(datas);

        computeShader.SetBuffer(kernelId, "_Buffer", computeBuffer);
        visibleMaterial.SetBuffer("_Buffer", computeBuffer);
        visibleMaterial.SetVector("_Up", target.transform.up);

        // indirect args
        var args = new uint[4];
        args[0] = target.sharedMesh.GetIndexCount(0);
        args[1] = (uint) visibleCount;
        args[2] = target.sharedMesh.GetIndexStart(0);
        args[3] = target.sharedMesh.GetBaseVertex(0);
       
        argsBuffer?.Release();
        argsBuffer = new ComputeBuffer(1, sizeof(uint) * args.Length, ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(args);
        
    }
    
    private void Draw()
    {
        
        if (visibleMaterial == null || argsBuffer == null || visibleMesh == null) return;
        
        computeShader.SetMatrix("_LocalToWorldMatrix",target.transform.localToWorldMatrix);
        computeShader.SetMatrix("_Rotation", Matrix4x4.Rotate(target.transform.rotation));
        computeShader.Dispatch(kernelId, Mathf.Max(visibleCount / 8, 1), 1, 1);

        Graphics.DrawMeshInstancedIndirect(visibleMesh, 0, visibleMaterial,
            new Bounds(Vector3.zero, Vector3.one * 32f), argsBuffer);
    }

    private void OnDestroy()
    {
        computeBuffer.Release();
        argsBuffer.Release();
        ;
    }
}
