using System;
using UnityEditor;
using UnityEngine;
using Object = UnityEngine.Object;

namespace Hekky {
    // Material property drawers
    public static partial class HGUI {
        internal static void DrawDirectionalSphere(Vector3 direction) {
            // Load resources
            Mesh unitySphere = Resources.GetBuiltinResource<Mesh>("Sphere.fbx");
            Shader editorNdotLShader = Resources.Load<Shader>("Hidden/PropertyDrawers/Direction");

        }
    }
    
    // 3D Directional vector
    public class HekkyDirection3DDrawer : MaterialPropertyDrawer {
        
        bool m_hovering = false;
        bool m_dragging = false;
        
        // Draw the property inside the given rect
        public override void OnGUI (Rect position, MaterialProperty prop, String label, MaterialEditor editor)
        {
            // Editor prop setup
            Vector4 value = prop.vectorValue.normalized;

            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = prop.hasMixedValue;
            
            // Vector 4 raw
            // position.width = EditorGUIUtility.currentViewWidth;
            var newPosition = position;
            newPosition.width = EditorGUIUtility.currentViewWidth - EditorGUIUtility.fieldWidth;
            value = EditorGUI.Vector4Field(newPosition, label, value).normalized;

            // Compute render region
            Rect rect;
            if (EditorGUIUtility.currentViewWidth < 329f)
            {
                rect = EditorGUILayout.GetControlRect(false, 110f);
                rect.yMin += 20f;
            }
            else
            {
                rect = EditorGUILayout.GetControlRect(false, 90f);
            }
            
            // Get bounding Rects
            var dragRect = rect;
            dragRect.xMin += -60.0f;
            dragRect.width = 120.0f;
            dragRect.y += 10.0f;
            dragRect.height = 80.0f;
            
            // rect.xMin   += 80;
            rect.y      += 50;
            
            // Process events
            var evt = Event.current;

            if ( dragRect.Contains(evt.mousePosition) || m_dragging) {
                if ( !m_hovering ) {
                    m_hovering = true;
                    editor.Repaint();
                }
            } else {
                m_hovering = false;
                editor.Repaint();
            }

            if ( evt.type == EventType.MouseDrag & ( dragRect.Contains(evt.mousePosition) || m_dragging ) ) {

                Vector2 deltaMouse = evt.mousePosition - rect.position;
                deltaMouse.y *= -1.0f;
                deltaMouse *= 1.0f / 30.0f; // Scale with frame rate
                float depth = 1.0f - deltaMouse.magnitude;

                prop.vectorValue = new Vector4(deltaMouse.x, deltaMouse.y, depth, 0.0f).normalized;
                
                m_dragging = true;
                editor.Repaint();

            } else {
                m_dragging = false;
            }
            
            if ( evt.type == EventType.Repaint ) {
                Mesh sphere         = Resources.GetBuiltinResource<Mesh>("Sphere.fbx");
                Shader shader       = HekkyUtil.FetchShaderByName("Direction");
                Material material   = new Material(shader);
                
                GUI.BeginClip(rect);
                GL.PushMatrix();
                GL.Begin(GL.TRIANGLES);

                material.SetVector("_Direction", prop.vectorValue);
                material.SetPass(0);
                
                var newMat = GL.modelview;
                newMat.SetTRS(Vector3.forward * -60.0f, Quaternion.identity, Vector3.one * 30f);
                Graphics.DrawMeshNow(sphere, newMat);

                GL.End();
                GL.PopMatrix();
                GUI.EndClip();
                
                Object.DestroyImmediate(material);
            }

            // Finalizing
            EditorGUI.showMixedValue = false;
            if (EditorGUI.EndChangeCheck())
            {
                // Set the new value if it has changed
                prop.vectorValue = value.normalized; // This is a direction so we normalize it
            }
        }
    }
    
    // 2D Directional vector
    public class HekkyDirection2DDrawer : MaterialPropertyDrawer {
        
        bool m_hovering = false;
        bool m_dragging = false;
        
        // Draw the property inside the given rect
        public override void OnGUI (Rect position, MaterialProperty prop, String label, MaterialEditor editor)
        {
            // Editor prop setup
            Vector4 value = prop.vectorValue.normalized;

            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = prop.hasMixedValue;
            
            // Vector 4 raw
            // position.width = EditorGUIUtility.currentViewWidth;
            var newPosition = position;
            newPosition.width = EditorGUIUtility.currentViewWidth - EditorGUIUtility.fieldWidth;
            value = EditorGUI.Vector4Field(newPosition, label, value).normalized;

            // Compute render region
            Rect rect;
            if (EditorGUIUtility.currentViewWidth < 329f)
            {
                rect = EditorGUILayout.GetControlRect(false, 110f);
                rect.yMin += 20f;
            }
            else
            {
                rect = EditorGUILayout.GetControlRect(false, 90f);
            }
            
            // Get bounding Rects
            var dragRect = rect;
            dragRect.xMin += -60.0f;
            dragRect.width = 120.0f;
            dragRect.y += 10.0f;
            dragRect.height = 80.0f;
            
            // rect.xMin   += 80;
            rect.y      += 50;
            
            // Process events
            var evt = Event.current;

            if ( dragRect.Contains(evt.mousePosition) || m_dragging) {
                if ( !m_hovering ) {
                    m_hovering = true;
                    editor.Repaint();
                }
            } else {
                m_hovering = false;
                editor.Repaint();
            }

            if ( evt.type == EventType.MouseDrag & ( dragRect.Contains(evt.mousePosition) || m_dragging ) ) {

                Vector2 deltaMouse = evt.mousePosition - rect.position;
                deltaMouse.y *= -1.0f;
                deltaMouse *= 1.0f / 30.0f; // Scale with frame rate

                prop.vectorValue = new Vector4(deltaMouse.x, deltaMouse.y, 0.0f, 0.0f).normalized;
                
                m_dragging = true;
                editor.Repaint();

            } else {
                m_dragging = false;
            }
            
            if ( evt.type == EventType.Repaint ) {
                Mesh sphere         = Resources.GetBuiltinResource<Mesh>("Sphere.fbx");
                Shader shader       = HekkyUtil.FetchShaderByName("Direction");
                Material material   = new Material(shader);
                
                GUI.BeginClip(rect);
                GL.PushMatrix();
                GL.Begin(GL.TRIANGLES);

                material.SetVector("_Direction", prop.vectorValue);
                material.SetPass(0);
                
                var newMat = GL.modelview;
                newMat.SetTRS(Vector3.forward * -60.0f, Quaternion.identity, Vector3.one * 30f);
                Graphics.DrawMeshNow(sphere, newMat);

                GL.End();
                GL.PopMatrix();
                GUI.EndClip();
                
                Object.DestroyImmediate(material);
            }

            // Finalizing
            EditorGUI.showMixedValue = false;
            if (EditorGUI.EndChangeCheck())
            {
                // Set the new value if it has changed
                prop.vectorValue = value.normalized; // This is a direction so we normalize it
            }
        }
    }
}
