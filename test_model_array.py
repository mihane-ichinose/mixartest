import coremltools
import numpy as np
import PIL.Image

#model = ct.models.MLModel('/Users/zhuang52/Downloads/measure_vol_array.mlpackage')

Height = 528  # use the correct input image height
Width = 528  # use the correct input image width

# Assumption: the mlmodel's input is of type MultiArray and of shape (1, 3, Height, Width).
model_expected_input_shape = (1, Height, Width, 3) # depending on the model description, this could be (3, Height, Width)

# Load the model.
model = coremltools.models.MLModel('./measure_vol_array.mlpackage')

def load_image_as_numpy_array(path, resize_to=None):
    # resize_to: (Width, Height)
    mean_RGB = [144.80, 148.56, 156.39]
    mean_RGB = np.array(mean_RGB)
    img = PIL.Image.open(path)
#    if resize_to is not None:
#        img = img.resize(resize_to, PIL.Image.ANTIALIAS)
    if resize_to is not None:
        img = img.resize(resize_to, PIL.Image.ANTIALIAS)
    img_np = np.array([img]) - mean_RGB[None, None, None, :] 
    img_np /= 127.5
    img_np = img_np.astype(np.float32) # shape of this numpy array is (Height, Width, 3)
    return img_np

# Load the image and resize using PIL utilities.
img_as_np_array = load_image_as_numpy_array('/Users/zhuang52/Downloads/test/Est_Rio_R_Dura_75_nd_nf_bl_sin_me_cen.JPG', resize_to=(Width, Height)) # shape (Height, Width, 3)

# PIL returns an image in the format in which the channel dimension is in the end,
# which is different than Core ML's input format, so that needs to be modified.
#img_as_np_array = np.transpose(img_as_np_array, (2,0,1)) # shape (3, Height, Width)

# Add the batch dimension if the model description has it.
img_as_np_array = np.reshape(img_as_np_array, model_expected_input_shape)

# Now call predict.
out_dict = model.predict({'input_1': img_as_np_array})
print(out_dict)
# Load the image and resize using PIL utilities.
img_as_np_array = load_image_as_numpy_array('/Users/zhuang52/Downloads/test/Est_Rio_R_Dura_200_nd_nf_bl_sin_me_cen.JPG', resize_to=(Width, Height)) # shape (Height, Width, 3)

# PIL returns an image in the format in which the channel dimension is in the end,
# which is different than Core ML's input format, so that needs to be modified.
#img_as_np_array = np.transpose(img_as_np_array, (2,0,1)) # shape (3, Height, Width)

# Add the batch dimension if the model description has it.
img_as_np_array = np.reshape(img_as_np_array, model_expected_input_shape)

# Now call predict.
out_dict = model.predict({'input_1': img_as_np_array})
print(out_dict)

# Load the image and resize using PIL utilities.
img_as_np_array = load_image_as_numpy_array('/Users/zhuang52/Downloads/test/Est_Rio_C_Dura_50_nd_nf_bl_sin_al_sup1.JPG', resize_to=(Width, Height)) # shape (Height, Width, 3)

# PIL returns an image in the format in which the channel dimension is in the end,
# which is different than Core ML's input format, so that needs to be modified.
#img_as_np_array = np.transpose(img_as_np_array, (2,0,1)) # shape (3, Height, Width)

# Add the batch dimension if the model description has it.
#img_as_np_array = np.reshape(img_as_np_array, model_expected_input_shape)

# Now call predict.
out_dict = model.predict({'input_1': img_as_np_array})
print(out_dict)

