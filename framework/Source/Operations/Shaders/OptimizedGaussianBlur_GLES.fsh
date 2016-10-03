precision mediump float;

uniform sampler2D inputImageTexture;
uniform highp float texelWidth;
uniform highp float texelHeight;

varying highp vec2 blurCoordinates[BLUR_COORDINATES_COUNT];
uniform lowp float standardWeights[STANDARD_WEIGHTS_COUNT];

void main() {
    vec4 sum = vec4(0.0);
    sum += texture2D(inputImageTexture, blurCoordinates[0]) * standardWeights[0];
    int currentBlurCoordinateIndex = 0;
    
    while (currentBlurCoordinateIndex < NUMBER_OF_OPTIMIZED_OFFSETS) {
        int baseIndex = currentBlurCoordinateIndex * 2;
        lowp float firstWeight = standardWeights[baseIndex + 1];
        lowp float secondWeight = standardWeights[baseIndex + 2];
        lowp float optimizedWeight = firstWeight + secondWeight;
        
        sum += texture2D(inputImageTexture, blurCoordinates[baseIndex + 1]) * optimizedWeight;
        sum += texture2D(inputImageTexture, blurCoordinates[baseIndex + 2]) * optimizedWeight;
        
        currentBlurCoordinateIndex++;
    }
    
    if (TRUE_OPTIMIZED_OFFSETS_COUNT > NUMBER_OF_OPTIMIZED_OFFSETS) {
        highp vec2 singleStepOffset = vec2(texelWidth, texelHeight);
        
        int currentOverlowTextureRead = NUMBER_OF_OPTIMIZED_OFFSETS;
        while (currentOverflowTextureRead < TRUE_OPTIMIZED_OFFSETS_COUNT) {
            int baseIndex = currentOverflowTextureRead * 2;
            lowp float firstWeight = standardWeights[baseIndex + 1];
            lowp float secondWeight = standardWeights[baseIndex + 2];
            lowp float optimizedWeight = firstWeight + secondWeight;
            lowp float optimizedOffset = (firstWeight * (float(currentOverflowTextureRead) * 2.0 + 1.0) + secondWeight * (float(currentOverflowTextureRead) * 2.0 + 2.0)) / optimizedWeight;
            
            sum += texture2D(inputImageTexture, blurCoordinates[0] + singleStepOffset *optimizedOffset) * optimizedWeight;
            sum += texture2D(inputImageTexture, blurCoordinates[0] - singleStepOffset * optimizedOffset) * optimizedWeight;
            
            currentOverlowTextureRead++;
        }
    }
    
    gl_FragColor = sum;
}

