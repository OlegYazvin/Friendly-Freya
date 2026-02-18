#pragma once

#include <array>

namespace model {

struct TreeClusterPoint {
  float x = 0.0f;
  float y = 0.0f;
  float z = 0.0f;
  float rx = 0.0f;
  float ry = 0.0f;
  float shade = 0.0f;
};

struct TreeModelConfig {
  float windSpeed = 0.42f;
  float windAmp = 1.25f;
  float trunkHeight = 33.0f;
  float trunkHalfWidth = 0.12f;
  float trunkDepth = 0.06f;
  float trunkLeanAmp = 0.035f;
  float canopyHighlightAlpha = 0.18f;
};

inline constexpr TreeModelConfig kTreeModel{};

inline constexpr std::array<TreeClusterPoint, 8> kTreeCanopy = {{
  {-0.34f, -0.12f, 28.0f, 9.0f, 6.9f, -0.05f},
  {-0.1f, -0.24f, 33.0f, 9.5f, 7.2f, 0.03f},
  {0.16f, -0.2f, 31.0f, 8.9f, 6.7f, -0.02f},
  {0.34f, -0.06f, 29.0f, 8.6f, 6.5f, -0.07f},
  {-0.25f, 0.1f, 30.0f, 8.7f, 6.6f, -0.04f},
  {0.03f, 0.16f, 34.0f, 9.9f, 7.4f, 0.07f},
  {0.28f, 0.14f, 30.0f, 8.8f, 6.4f, -0.03f},
  {0.0f, -0.04f, 40.0f, 7.4f, 5.7f, 0.11f}
}};

}  // namespace model
