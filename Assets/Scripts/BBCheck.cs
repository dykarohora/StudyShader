using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class BBCheck : MonoBehaviour
{
    private float param = 0.0f;
    void Update()
    {
        param += 0.015f;
        if (2.0f <= param && param <= 5.0f)
        {
            var materials = GetComponent<Renderer>().materials;
            foreach(var mat in materials)
            if (mat.HasProperty("_Reconstruction"))
            {
                mat.SetFloat("_Reconstruction", param - 2.0f);
            }
        }

        if (param >= 6.0f)
        {
            param = 0.0f;
            var materials = GetComponent<Renderer>().materials;
            foreach(var mat in materials)
            if (mat.HasProperty("_Reconstruction"))
            {
                mat.SetFloat("_Reconstruction", param - 2.0f);
            }
        }
    }
}
