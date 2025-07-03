# Pixelart Shader
#### Video Demo: [https://www.youtube.com/watch?v=Vj7k8jxJ58s]
#### Description: 
This is a ReShade shader that is designed to turn games into a faked pixel-art style. The shader also allows for custom color palettes to be inputted by the user. It works with ReShade 6.5.1 and up for sure.

The shader works on games that do not have depth buffer access.

Technical Requirements
- Step 1, have reshade installed and make sure it's version 6.5.1 or higher (it should work with older versions but I have not tested it so use at your own risk)
- Step 2, drag the PixelartShader.fx file into the Shaders folder of your game. (path "C:\pathToYourGame\gameFolder\reshade-shaders\Shaders")
- Step 3, Launch your game once it has loaded, press the home key to pull up reshade's UI.
- Step 4, Search for the PixelArtShader file using reshade's search function and click the checkbox on the left of the shader name.

You're done

INSTRUCTIONS FOR SETUP OF CUSTOM COLORPALETTES
- Take your color palette file, make sure it is a png and also of a 512x128 resolution. Also take not of the filename, you're gonna need it later. I recommend using https://coolors.co/ to create your color palette and then manually resizing and cropping the downloaded file (I know its a pain but I don't think there's an easier way). Some example color palettes are within the "palettes" folder on this github.
- The palette size can be as big as 255 and at minimum of 2.
- Go into the textures folder within your reshade folder within your game ("C:\pathToYourGame\gameFolder\reshade-shaders\Textures"). Then put the color palette file in the textures folder.
- Now that your texture is in your folder, open the ReShade UI and navigate to the PixelArtShader.fx file. Then, you're gonna want to right-click the file and click "Edit Source Code".
- Once you've opened the source code navigate to the line containing "texture ColorLUT <source = "PutFilenameHere.png";>" (should be line 70 as of writing this).
- Change the PutFilenameHere text to the name of your colorpalette file keeping the .png at the end. DO NOT MODIFY ANY OTHER PART OF THE SOURCE CODE UNLESS YOU KNOW WHAT YOU'RE DOING!
- Hit left ctrl + S to save the source code.
- Now check the "CustomPalette" checkbox in the bottom left of your screen and set the "CustomPaletteSize" slider to the amount of colors in your color palette.
- hit the ESC key on your keyboard to close the ReShade UI.

Your shader should be working now. If the screen has turned black upon the enabling of the shader, it most likely means there's a typo in the filename you inputted.

**(FYI I was submitting this project as my CS50 final project. The text below this is a report on the techniques and functionality of the project. If you're not a member of the CS50 staff, you do not have to read this unless you're interested)**

The first thing that needs to be done for creating a shader that mimics pixelart behavior is to understand the actual properties of pixelart and only then can we begin thinking about how a shader effect can mimick these properties. One of the first properties of pixelart that comes to mind is the accentuated pixels and a low resolution. The second property of pixelart is a limited color palette. And lastly a focus on crisp edges. These are the properties that our shader should attempt to mimic. There are also other considerations that are not exclusive to pixel art that must be taken into account when making a shader. These constraints being performance, loss of detail and the amount of creative control given to the user (there are of course many more but these are the main relevant ones for this project). With pixel art, loss of detail within the frame is inevitable due to the nature of the artstyle however, depending on the techniques used to achieve it, loss of detail can be minimized.

##Downscaling step

In order to achieve a low resolution, a given frame needs to be downscaled to said resolution. In the first pass of the shader, we take the frame and place it into a buffer 2 mipmap levels lower than the original render. The reason I chose 2 mipmap levels instead of any other amount is because I felt that downscaling to the 2nd mipmap level gave a nice balance between the retention of detail and achieving a sufficient level of downscaling for pixel art. Normally I would design the shader in a way that allows the user to choose a mipmap level, however the dimensions of buffers that the mipmap value is supposed to calculate can't be modified during runtime. This makes designing the shader in a way that the user can select the mipmap level conveniently impossible.

The reason we want to place it into a buffer a quarter the size is because it is what causes the downsize. After putting our shader into the buffer, we sample from it using point filtering mode and apply it to the backbuffer (or the screen). The reason we wish to use point filtering mode for sampling the texture is because point-filtering retains the colors as the image is downscaled or upscaled by simply taking the closest texel, unlike the default linear filtering method which linearly interpolates between many texels. Point filtering is also faster due to it's relative simplicity. The reason we immediately wish to apply the downsized buffer to the backbuffer (in other words, the screen) is because of certain constraints ReShade has. ReShade doesn't allow for sampling and storing into custom buffers at the same time within the same shader pass unless we're using the backbuffer. Using the backbuffer therefore makes things much more convenient to implement.

##The dithering pass

The reason that dithering is a useful step for a shader effect like this is because dithering helps reduce color banding artifacts and also can help contribute to the pixel-artstyle effect. Which dithering technique to use and looks best is more of an artistic decision than a practical one, so I decided to go with Bayer dithering. Allowing the user to select a dithering style could be a future expansion which offers more artistic control to the user but I felt it was out of the scope of the CS50 final project submission. I do intend on implementing selectable dithering methods after CS50. Bayer dithering works by calculating a threshold map and then using the values of the threshold map to calculate the color of a pixel. Ill be using the 4x4 threshold map because it is the largest matrix dimension possible that is till supported by ReShade and also looks nicer compared to the 2x2 map. While it is possible to compute the values of the map in real-time using a formula, it is extremely slow so we're better of precomputing the values and storing them in a matrix.

##Color quantization

Color quantization is an effect that is designed to reduce the number of colors in a given frame. This is one of the first effects that comes to mind when it comes to pixelart as reducing the color palette is something it strives for. Color quantization works by taking a user-inputted number of colors per channel, subtracting 1, then multiplying it by the color of a given pixel and taking the floor. Once the floor is taken, the value is then divided by the colors per channel - 1. My code for color quantization is slightly modified however. If the user chooses to opt into the custom color palette, the color is also converted into greyscale by setting the green and blue channels equal to the red channel. Why we turn the values greyscale because it makes it possible to do color swapping later using luminance or hue or saturation if desired.

##Palette swap

The last and arguably most important step of the pipeline is the palette swap step. If we take the greyscaled version of a given pixel, since it is color quantized, it becomes possible to use the value as the position within a color palette lookup table. The way the shader does this is by taking asking the user for a png image input and then sampling from the png image as if it where a lookup table and using the grey-scaled value as a coordinate for the coordinate. This also means that it becomes possible for the user to input any color palette of their own into the shader as long as it confines to the specified resolution of 512x128. The reason I chose these values is because they are powers of 2 and scale nicely as a result.

Sources for many of the resources used:
Dithering article: https://en.wikipedia.org/wiki/Dither
