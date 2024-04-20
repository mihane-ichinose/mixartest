import coremltools as ct
import tensorflow as tf

model_path = '/Users/zhuang52/Downloads/final_model.h5'

keras_model =  tf.keras.models.load_model(model_path, compile=False)

model = ct.convert(keras_model, inputs=[ct.ImageType(bias=[-144.80/127.5, -148.56/127.5, -156.39/127.5], scale=1/127.5)], convert_to="mlprogram", compute_precision=ct.precision.FLOAT32)
#model = ct.convert(keras_model, convert_to="mlprogram")
model.save("measure_vol.mlpackage")
#model.save("measure_vol_array.mlpackage")
