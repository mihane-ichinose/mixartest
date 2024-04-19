import coremltools as ct
import numpy as np
import PIL.Image

model = ct.models.MLModel('/Users/zhuang52/Downloads/measure_vol.mlpackage', compute_units=ct.ComputeUnit.CPU_ONLY)
Height = 528  # use the correct input image height
Width = 528  # use the correct input image width


# Scenario 1: load an image from disk.
def load_image(path, resize_to=None):
    # resize_to: (Width, Height)
    img = PIL.Image.open(path)
    if resize_to is not None:
        img = img.resize(resize_to, PIL.Image.ANTIALIAS)
    img_np = np.array(img).astype(np.float32)
    print(img_np)
    return img_np, img


# Load the image and resize using PIL utilities.
img_np, img = load_image('/Users/zhuang52/Downloads/b757319d-962f-45a9-b294-8fa04b1f506e.jpeg', resize_to=(Width, Height))
print(img)
out_dict = model.predict({'input_1': img_np})
print(out_dict)

# Scenario 2: load an image from a NumPy array.
shape = (Height, Width, 3)  # height x width x RGB
data = np.zeros(shape, dtype=np.uint8)
# manipulate NumPy data
pil_img = PIL.Image.fromarray(data)
out_dict = model.predict({'input_1': pil_img})
print(out_dict)
