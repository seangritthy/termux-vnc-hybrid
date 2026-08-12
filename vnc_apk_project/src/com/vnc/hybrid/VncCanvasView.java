package com.vnc.hybrid;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.util.AttributeSet;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.view.ScaleGestureDetector;
import android.view.View;

public class VncCanvasView extends View {

    private Bitmap framebufferBitmap;
    private final Paint paint = new Paint(Paint.FILTER_BITMAP_FLAG | Paint.ANTI_ALIAS_FLAG);
    private RfbClient rfbClient;

    private final Matrix matrix = new Matrix();
    private final Matrix inverseMatrix = new Matrix();

    private ScaleGestureDetector scaleDetector;
    private GestureDetector gestureDetector;

    private int mouseMask = 1; // 1 = Left Click, 2 = Middle Click, 4 = Right Click

    public VncCanvasView(Context context) {
        super(context);
        init(context);
    }

    public VncCanvasView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init(context);
    }

    private void init(Context context) {
        scaleDetector = new ScaleGestureDetector(context, new ScaleListener());
        gestureDetector = new GestureDetector(context, new GestureListener());
    }

    public void setRfbClient(RfbClient client) {
        this.rfbClient = client;
    }

    public void setFramebuffer(Bitmap bitmap) {
        this.framebufferBitmap = bitmap;
        postInvalidate();
    }

    public void setMouseMask(int mask) {
        this.mouseMask = mask;
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        if (framebufferBitmap != null && !framebufferBitmap.isRecycled()) {
            canvas.drawBitmap(framebufferBitmap, matrix, paint);
        }
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        scaleDetector.onTouchEvent(event);
        gestureDetector.onTouchEvent(event);

        if (event.getActionMasked() == MotionEvent.ACTION_UP) {
            sendPointerEvent(event, 0); // Pointer up
        }
        return true;
    }

    private void sendPointerEvent(MotionEvent event, int mask) {
        if (rfbClient == null || framebufferBitmap == null) return;

        matrix.invert(inverseMatrix);
        float[] pts = new float[]{event.getX(), event.getY()};
        inverseMatrix.mapPoints(pts);

        int rx = Math.round(pts[0]);
        int ry = Math.round(pts[1]);

        if (rx >= 0 && rx < framebufferBitmap.getWidth() && ry >= 0 && ry < framebufferBitmap.getHeight()) {
            rfbClient.sendPointerEvent(rx, ry, mask);
        }
    }

    private class ScaleListener extends ScaleGestureDetector.SimpleOnScaleGestureListener {
        @Override
        public boolean onScale(ScaleGestureDetector detector) {
            float scaleFactor = detector.getScaleFactor();
            matrix.postScale(scaleFactor, scaleFactor, detector.getFocusX(), detector.getFocusY());
            postInvalidate();
            return true;
        }
    }

    private class GestureListener extends GestureDetector.SimpleOnGestureListener {
        @Override
        public boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX, float distanceY) {
            if (scaleDetector.isInProgress()) return false;
            matrix.postTranslate(-distanceX, -distanceY);
            postInvalidate();
            return true;
        }

        @Override
        public boolean onSingleTapConfirmed(final MotionEvent e) {
            sendPointerEvent(e, mouseMask);
            postDelayed(new Runnable() {
                @Override
                public void run() {
                    sendPointerEvent(e, 0);
                }
            }, 50);
            return true;
        }

        @Override
        public boolean onDoubleTap(final MotionEvent e) {
            sendPointerEvent(e, 4); // Right click on double tap
            postDelayed(new Runnable() {
                @Override
                public void run() {
                    sendPointerEvent(e, 0);
                }
            }, 50);
            return true;
        }

        @Override
        public void onLongPress(final MotionEvent e) {
            sendPointerEvent(e, 2); // Middle click on long press
            postDelayed(new Runnable() {
                @Override
                public void run() {
                    sendPointerEvent(e, 0);
                }
            }, 50);
        }
    }
}
