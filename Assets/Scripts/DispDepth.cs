using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DispDepth : MonoBehaviour
{
    public Material mat;
    // Start is called before the first frame update
    private void Start()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        Graphics.Blit(src, dest, mat);
    }
}
