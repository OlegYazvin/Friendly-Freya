#pragma once

namespace model {

struct BuildingModelConfig {
  float alleyHalfWidth = 0.58f;
  float alleyConnectorHalfWidth = 0.46f;
  float alleyNearBuildingGap = 0.03f;
  float streetSideSetback = 0.6f;
  float alleyEdgeInset = 0.42f;
  float branchHalfWidth = 0.5f;

  float roofLift = 0.24f;
  float parapetBase = 5.4f;
  float parapetPerFloor = 1.6f;
  float parapetMin = 6.2f;
  float parapetMax = 12.4f;
  float roofSlabDrop = 2.2f;
  float roofTexUScale = 0.76f;
  float roofTexVScale = 0.74f;

  float corniceBase = 6.0f;
  float cornicePerFloor = 1.2f;
  float corniceMin = 7.0f;
  float corniceMax = 11.8f;
};

inline constexpr BuildingModelConfig kBuildingModel{};

}  // namespace model
