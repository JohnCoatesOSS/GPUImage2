uniform sampler2D inputImageTexture;
uniform float texelWidth;
uniform float texelHeight;

varying vec2 blurCoordinates[BLUR_COORDINATES_COUNT];
uniform float standardWeights[STANDARD_WEIGHTS_COUNT];

void main() {
    vec4 sum = vec4(0.0);
    sum += texture2D(inputImageTexture, blurCoordinates[0]) * standardWeights[0];
    int currentBlurCoordinateIndex = 0;
    
    while (currentBlurCoordinateIndex < NUMBER_OF_OPTIMIZED_OFFSETS) {
        int baseIndex = currentBlurCoordinateIndex * 2;
        float firstWeight = standardWeights[baseIndex + 1];
        float secondWeight = standardWeights[baseIndex + 2];
        float optimizedWeight = firstWeight + secondWeight;
        
        sum += texture2D(inputImageTexture, blurCoordinates[baseIndex + 1]) * optimizedWeight;
        sum += texture2D(inputImageTexture, blurCoordinates[baseIndex + 2]) * optimizedWeight;
        
        currentBlurCoordinateIndex++;
    }
    
    if (TRUE_OPTIMIZED_OFFSETS_COUNT > NUMBER_OF_OPTIMIZED_OFFSETS) {
        vec2 singleStepOffset = vec2(texelWidth, texelHeight);
        
        int currentOverflowTextureRead = NUMBER_OF_OPTIMIZED_OFFSETS;
        while (currentOverflowTextureRead < TRUE_OPTIMIZED_OFFSETS_COUNT) {
            int baseIndex = currentOverflowTextureRead * 2;
            float firstWeight = standardWeights[baseIndex + 1];
            float secondWeight = standardWeights[baseIndex + 2];
            float optimizedWeight = firstWeight + secondWeight;
            float optimizedOffset = (firstWeight * (float(currentOverflowTextureRead) * 2.0 + 1.0) + secondWeight * (float(currentOverflowTextureRead) * 2.0 + 2.0)) / optimizedWeight;
            
            sum += texture2D(inputImageTexture, blurCoordinates[0] + singleStepOffset *optimizedOffset) * optimizedWeight;
            sum += texture2D(inputImageTexture, blurCoordinates[0] - singleStepOffset * optimizedOffset) * optimizedWeight;
            
            currentOverflowTextureRead++;
        }
    }
    
    gl_FragColor = sum;
}

