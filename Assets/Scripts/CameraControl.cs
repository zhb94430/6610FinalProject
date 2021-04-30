using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// http://coffeebreakcodes.com/move-zoom-and-rotate-camera-unity3d/

public class CameraControl : MonoBehaviour
{
    public float moveSpeed = 2.0f;

    public float zoomSpeed = 2.0f;


    // Rotation
    public float minX = -360.0f;
    public float maxX = 360.0f;

    public float minY = -45.0f;
    public float maxY = 45.0f;

    public float sensX = 100.0f;
    public float sensY = 100.0f;

    float rotationY = 0.0f;
    float rotationX = 0.0f;

    // Ray Marching
    private Camera currentCamera;

    // Start is called before the first frame update
    void Start()
    {
        currentCamera = Camera.main;

        currentCamera.depthTextureMode = DepthTextureMode.Depth;
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKey(KeyCode.RightArrow))
        {
            transform.position += Vector3.right * moveSpeed * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.LeftArrow))
        {
            transform.position += Vector3.left * moveSpeed * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.UpArrow))
        {
            transform.position += Vector3.forward * moveSpeed * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.DownArrow))
        {
            transform.position += Vector3.back * moveSpeed * Time.deltaTime;
        }

        float scroll = Input.GetAxis("Mouse ScrollWheel");
        transform.Translate(0, scroll * zoomSpeed, scroll * zoomSpeed, Space.World);

        if (Input.GetMouseButton(0))
        {
            rotationX += Input.GetAxis("Mouse X") * sensX * Time.deltaTime;
            rotationY += Input.GetAxis("Mouse Y") * sensY * Time.deltaTime;
            rotationY = Mathf.Clamp(rotationY, minY, maxY);
            transform.localEulerAngles = new Vector3(-rotationY, rotationX, 0);
        }

        Matrix4x4 viewProjM = currentCamera.projectionMatrix * currentCamera.worldToCameraMatrix;

        Shader.SetGlobalVector("cameraPos", transform.position);
        Shader.SetGlobalMatrix("inverseViewProjM", viewProjM.inverse);
    }
}
