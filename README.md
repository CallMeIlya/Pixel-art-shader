# Pixel-art-shader
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
- Go into the textures folder within your reshade folder within your game ("C:\pathToYourGame\gameFolder\reshade-shaders\Textures"). Then put the color palette file in the textures folder.
- Now that your texture is in your folder, open the ReShade UI and navigate to the PixelArtShader.fx file. Then, you're gonna want to right-click the file and click "Edit Source Code".
- Once you've opened the source code navigate to the line containing "texture ColorLUT <source = "PutFilenameHere.png";>" (should be line 70 as of writing this).
- Change the PutFilenameHere text to the name of your colorpalette file keeping the .png at the end. DO NOT MODIFY ANY OTHER PART OF THE SOURCE CODE UNLESS YOU KNOW WHAT YOU'RE DOING!
- Hit left ctrl + S to save the source code.
- Now check the "CustomPalette" checkbox in the bottom left of your screen and set the "CustomPaletteSize" slider to the amount of colors in your color palette.
- hit the ESC key on your keyboard to close the ReShade UI.

Your shader should be working now. If the screen has turned black upon the enabling of the shader, it most likely means there's a typo in the filename you inputted.

