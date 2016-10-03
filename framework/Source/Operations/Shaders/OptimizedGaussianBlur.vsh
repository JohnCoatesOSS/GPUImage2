attribute vec4 position;
attribute vec4 inputTextureCoordinate;
uniform float texelWidth;
uniform float texelHeight;

varying vec2 blurCoordinates[BLUR_COORDINATES_COUNT];
uniform float optimizedOffsets[OPTIMIZED_OFFSETS_COUNT];

void main() {
    gl_Position = position;
    vec2 singleStepOffset = vec2(texelWidth, texelHeight);
    vec2 textureCoordinate = inputTextureCoordinate.xy;
    blurCoordinates[0] = textureCoordinate;
    const int numberOfOptimizedOffsets = OPTIMIZED_OFFSETS_COUNT;

    for (int i=0; i < numberOfOptimizedOffsets; i++) {
        float optimizedOffset = optimizedOffsets[i];
        int coordinateOffset = i * 2;
        blurCoordinates[coordinateOffset + 1] = textureCoordinate + singleStepOffset * optimizedOffset;
        blurCoordinates[coordinateOffset + 2] = textureCoordinate - singleStepOffset * optimizedOffset;
    }
}
