import coremltools as ct
import numpy as np
import PIL.Image

model = ct.models.MLModel('./measure_vol.mlpackage', compute_units=ct.ComputeUnit.CPU_ONLY)
Height = 528  # use the correct input image height
Width = 528  # use the correct input image width


# Scenario 1: load an image from disk.
def load_image(path, resize_to=None):
    # resize_to: (Width, Height)
    img = PIL.Image.open(path)
    if resize_to is not None:
        img = img.resize(resize_to, PIL.Image.ANTIALIAS)
    img_np = np.array(img).astype(np.float32)
    return img_np, img


# Load the image and resize using PIL utilities.
img_np, img = load_image('/Users/zhuang52/Downloads/test/Est_Rio_R_Dura_75_nd_nf_bl_sin_me_cen.JPG', resize_to=(Width, Height))
out_dict = model.predict({'input_1': img})
print(out_dict)

# Scenario 2: load an image from a NumPy array.
shape = (Height, Width, 3)  # height x width x RGB
data = np.zeros(shape, dtype=np.uint8)
# manipulate NumPy data
pil_img = PIL.Image.fromarray(data)
out_dict = model.predict({'input_1': pil_img})
print(out_dict)
