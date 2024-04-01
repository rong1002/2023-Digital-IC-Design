import numpy as np
from PIL import Image
import cv2
import os
import torch
import torch.nn.functional as F
from torchvision import transforms

def ImgDat(img_file, dat_folder):
    img = img_file
    gray_img = Image.open(img).convert('L') 
    resize_img = gray_img.resize((64, 64)) 
    # resize_img = transforms.Resize(size=[64, 64], antialias=True) #resize
    gray_folder = dat_folder + '/resizedImg.png'
    # gray_folder = r'.\test\resizedImg.png'
    resize_img.save(gray_folder)
    resize_img = cv2.imread(gray_folder, 0)

    dat_name = dat_folder + '/img.dat'
    dat = open (dat_name, 'w')
    dat_img = []
    for i in resize_img:
        for j in i:
            bits = bin(j * 16)[2:]
            bits = "0" * (13 - len(bits)) + bits
            dat.write(bits + "\n")
            dat_img.append(bits)

def Layer0AndLayer1Dat(dat_folder):
    gray_folder = dat_folder + '/resizedImg.png'
    # gray_folder = r'.\test\resizedImg.png'
    resize_img = cv2.imread(gray_folder, 0)
    kernel = torch.tensor([[[
        [-0.0625, 0, -0.125, 0, -0.0625],
        [      0, 0,      0, 0,       0],
        [  -0.25, 0,      1, 0,   -0.25],
        [      0, 0,      0, 0,       0],
        [-0.0625, 0, -0.125, 0, -0.0625]]]
    ])

    padding_img = np.pad(resize_img, pad_width=2, mode='edge')
    padding_img = torch.from_numpy(padding_img).type(torch.FloatTensor)
    padding_img = torch.unsqueeze(padding_img, 0)
    padding_img = torch.unsqueeze(padding_img, 0)
    conv_img = (F.conv2d(padding_img, kernel, stride=1) - 0.75)
    relu_img = F.relu(conv_img*16)
    relu_img = torch.squeeze(relu_img, 0)
    relu_img = torch.squeeze(relu_img, 0)
    relu_img = relu_img.numpy().astype(int)

    layer0_name = dat_folder + './layer0_golden.dat'
    layer0 = open (layer0_name, 'w')
    layer0_img = []

    for i in relu_img:
        for j in i:
            bits = bin(j)[2:]
            bits = "0" * (13 - len(bits)) + bits
            layer0.write(bits + "\n")
            layer0_img.append(bits)

    layer1_name = dat_folder + './layer1_golden.dat'
    layer1 = open (layer1_name, 'w')
    layer1_img = []

    max_img = F.max_pool2d(F.relu(conv_img), kernel_size=(2, 2), stride=2)
    max_img = torch.squeeze(max_img, 0)
    max_img = torch.squeeze(max_img, 0)
    max_img = np.ceil(max_img.numpy()).astype(int)

    for i in max_img:
        for j in i:
            bits = bin(j*16)[2:]
            bits = "0" * (13 - len(bits)) + bits
            layer1.write(bits + "\n")
            layer1_img.append(bits)


if __name__ == "__main__":
    from argparse import ArgumentParser
    parser = ArgumentParser()
    parser.add_argument("--img_file", default="./images/bleach.png", help="file with images")
    parser.add_argument("--dat_folder", default="./test", help="Folder with dat")
    args = parser.parse_args()

    if not os.path.exists(args.dat_folder):
        os.makedirs(args.dat_folder)
        
    ImgDat(args.img_file, args.dat_folder)
    Layer0AndLayer1Dat(args.dat_folder)