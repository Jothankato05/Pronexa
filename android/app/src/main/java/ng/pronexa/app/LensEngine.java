package ng.pronexa.app;

import ai.onnxruntime.OnnxTensor;
import ai.onnxruntime.OrtEnvironment;
import ai.onnxruntime.OrtException;
import ai.onnxruntime.OrtSession;
import java.nio.FloatBuffer;
import java.util.Collections;

/**
 * Runs Pronexa's on-phone food recogniser (assets/models/pronexa-food-v1.onnx).
 *
 * <p>Plain Java with no Android dependencies, so the same class is tested on a desktop JVM
 * (tool/food_model/LensEngineCheck.java). Callers must use it from a background thread: loading
 * the 81 MB model and running it take seconds, and doing that on Android's main thread makes the
 * system kill the app as not responding.
 */
public final class LensEngine implements AutoCloseable {
  public static final int SIZE = 384;
  public static final int LABELS = 41;
  public static final int FEATURES = 1280;

  private final String modelPath;
  private final OrtEnvironment env = OrtEnvironment.getEnvironment();
  private OrtSession session;

  public LensEngine(String modelPath) {
    this.modelPath = modelPath;
  }

  private synchronized OrtSession session() throws OrtException {
    if (session == null) {
      OrtSession.SessionOptions options = new OrtSession.SessionOptions();
      // A few threads is enough for one photo and leaves the phone responsive.
      int cores = Runtime.getRuntime().availableProcessors();
      options.setIntraOpNumThreads(Math.max(1, Math.min(4, cores)));
      options.setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT);
      session = env.createSession(modelPath, options);
    }
    return session;
  }

  /** Loads the model ahead of the first photo. */
  public synchronized void load() throws OrtException {
    session();
  }

  /**
   * @param image 384 x 384 RGB values in 0..1, row by row (NHWC), as built by the app.
   * @return {scores, features}: one probability per label in label order, and the photo's
   *     unit-length fingerprint (the app's photo memory compares these to learn new foods).
   */
  public synchronized float[][] run(float[] image) throws OrtException {
    if (image == null || image.length != SIZE * SIZE * 3) {
      throw new IllegalArgumentException("Expected " + (SIZE * SIZE * 3) + " values");
    }
    long[] shape = {1, SIZE, SIZE, 3};
    try (OnnxTensor input = OnnxTensor.createTensor(env, FloatBuffer.wrap(image), shape);
        OrtSession.Result out = session().run(Collections.singletonMap("image", input))) {
      float[][] scores = (float[][]) out.get("scores").get().getValue();
      float[][] features = (float[][]) out.get("features").get().getValue();
      if (scores.length != 1 || scores[0].length != LABELS || features.length != 1 || features[0].length != FEATURES) {
        throw new IllegalStateException("Unexpected model output");
      }
      return new float[][] {scores[0], features[0]};
    }
  }

  @Override
  public synchronized void close() throws OrtException {
    if (session != null) {
      session.close();
      session = null;
    }
  }
}
