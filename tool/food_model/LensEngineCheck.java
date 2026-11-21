import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;
import ng.pronexa.app.LensEngine;

/**
 * Desktop check of the Android LensEngine against the real model, with the desktop build of the
 * same ONNX Runtime version (com.microsoft.onnxruntime:onnxruntime:1.28.0).
 *
 * <p>javac -cp onnxruntime-1.28.0.jar -d out android/app/src/main/java/ng/pronexa/app/LensEngine.java tool/food_model/LensEngineCheck.java
 * java -cp onnxruntime-1.28.0.jar:out LensEngineCheck assets/models/pronexa-food-v1.onnx input.f32 [runs]
 *
 * <p>input.f32 is the app's own prepared photo (test/food_lens_test.dart, PRONEXA_LENS_SAMPLE).
 */
public final class LensEngineCheck {
  public static void main(String[] args) throws Exception {
    byte[] raw = Files.readAllBytes(Path.of(args[1]));
    float[] image = new float[raw.length / 4];
    ByteBuffer.wrap(raw).order(ByteOrder.LITTLE_ENDIAN).asFloatBuffer().get(image);
    int runs = args.length > 2 ? Integer.parseInt(args[2]) : 1;
    try (LensEngine engine = new LensEngine(args[0])) {
      for (int r = 0; r < runs; r++) {
        long t = System.nanoTime();
        float[][] out = engine.run(image);
        float[] s = out[0];
        double norm = 0;
        for (float v : out[1]) norm += v * v;
        StringBuilder top = new StringBuilder();
        boolean[] used = new boolean[s.length];
        for (int k = 0; k < 4; k++) {
          int best = -1;
          for (int i = 0; i < s.length; i++) if (!used[i] && (best < 0 || s[i] > s[best])) best = i;
          used[best] = true;
          top.append(String.format("%d:%.3f ", best, s[best]));
        }
        System.out.printf("run %d: %d ms, top %s| fingerprint %d values, length %.4f%n", r + 1, (System.nanoTime() - t) / 1_000_000, top, out[1].length, Math.sqrt(norm));
      }
    }
  }
}
