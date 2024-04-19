import coremltools as ct
import tensorflow as tf

model_path = '/Users/zhuang52/Downloads/final_model.h5'

keras_model =  tf.keras.models.load_model(model_path, compile=False)

#model = ct.convert(keras_model, inputs=[ct.ImageType()], convert_to="mlprogram", compute_precision=ct.precision.INT8)
model = ct.convert(keras_model, convert_to="mlprogram")

model.save("measure_vol_array.mlpackage")
