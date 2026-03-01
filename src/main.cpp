#include <SDL.h>
#include <SDL_opengl.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cctype>
#include <iostream>
#include <random>
#include <string>
#include <unordered_map>
#include <vector>

#include "building_model.h"
#include "tree_model.h"

namespace {

constexpr float PI = 3.14159265358979323846f;

struct Vec2 {
  float x = 0.0f;
  float y = 0.0f;
};

struct Color {
  float r = 0.0f;
  float g = 0.0f;
  float b = 0.0f;
  float a = 1.0f;
};

enum class BuildingFront {
  South,
  North
};

struct Building {
  float x = 0.0f;
  float y = 0.0f;
  float w = 0.0f;
  float d = 0.0f;
  float h = 0.0f;
  Color wall;
  Color roof;
  Color trim;
  Color glass;
  BuildingFront front = BuildingFront::South;
};

struct Tree {
  float x = 0.0f;
  float y = 0.0f;
  float size = 1.0f;
};

struct Shrub {
  float x = 0.0f;
  float y = 0.0f;
  float size = 1.0f;
};

struct StreetLight {
  float x = 0.0f;
  float y = 0.0f;
};

struct Dog {
  Vec2 pos;
  float facing = 0.0f;
  float screenFacing = 0.0f;
  float speed = 1.0f;
  float wanderTimer = 0.0f;
  float barkCooldown = 0.0f;
  float step = 0.0f;
  float bodyScale = 1.0f;
  float legScale = 1.0f;
  float earDrop = 0.0f;
  float snoutScale = 1.0f;
  float furFluff = 1.0f;
  Color color;
};

struct Freya {
  Vec2 pos;
  float facing = -PI * 0.5f;
  float screenFacing = -PI * 0.5f;
  float speed = 3.25f;
  float hunger = 34.0f;
  float vomit = 0.0f;
  float social = 22.0f;
  float step = 0.0f;
  float vomitingTimer = 0.0f;
};

struct Poop {
  Vec2 pos;
  float phase = 0.0f;
};

struct VomitPuddle {
  Vec2 pos;
  float ttl = 0.0f;
};

struct BarkPulse {
  Vec2 pos;
  float age = 0.0f;
  float ttl = 0.0f;
  float r0 = 0.0f;
  float r1 = 0.0f;
  Color color;
};

struct FloatLabel {
  std::string text;
  Vec2 pos;
  float age = 0.0f;
  float ttl = 0.0f;
  Color color;
};

struct GrassPatch {
  Vec2 pos;
  float r = 0.0f;
  float shade = 0.0f;
};

struct GrassBlade {
  Vec2 pos;
  float h = 0.0f;
  float leanX = 0.0f;
  float leanY = 0.0f;
  float swayPhase = 0.0f;
  float brightness = 0.0f;
};

struct RoadScuff {
  Vec2 pos;
  float len = 0.0f;
  float alpha = 0.0f;
  float angle = 0.0f;
};

struct RectArea {
  float x0 = 0.0f;
  float y0 = 0.0f;
  float x1 = 0.0f;
  float y1 = 0.0f;
};

enum class RenderType {
  Building,
  Tree,
  Shrub,
  Light,
  Vomit,
  Poop,
  Dog,
  Freya
};

struct RenderItem {
  float depth = 0.0f;
  RenderType type = RenderType::Building;
  int index = 0;
};

enum class MaterialId {
  Grass = 0,
  Sidewalk,
  Road,
  Brick,
  Roof,
  Count
};

struct MaterialTexture {
  static constexpr int SIZE = 192;
  GLuint tex = 0;
  std::vector<uint8_t> baseRGB;
  std::vector<uint8_t> normalRGB;
  std::vector<uint8_t> litRGB;
};

constexpr float MAP_W = 96.0f;
constexpr float MAP_H = 84.0f;

float clampf(float value, float minValue, float maxValue) {
  return std::max(minValue, std::min(maxValue, value));
}

float lerpf(float a, float b, float t) {
  return a + (b - a) * t;
}

float distSq(const Vec2 &a, const Vec2 &b) {
  const float dx = a.x - b.x;
  const float dy = a.y - b.y;
  return dx * dx + dy * dy;
}

float distSqPointToSegment(const Vec2 &p, const Vec2 &a, const Vec2 &b) {
  const float abx = b.x - a.x;
  const float aby = b.y - a.y;
  const float abLenSq = abx * abx + aby * aby;
  if (abLenSq <= 0.000001f) {
    return distSq(p, a);
  }
  const float apx = p.x - a.x;
  const float apy = p.y - a.y;
  const float t = clampf((apx * abx + apy * aby) / abLenSq, 0.0f, 1.0f);
  const Vec2 closest{a.x + abx * t, a.y + aby * t};
  return distSq(p, closest);
}

float cross2(const Vec2 &a, const Vec2 &b, const Vec2 &p) {
  return (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
}

bool pointInTriangle(const Vec2 &p, const Vec2 &a, const Vec2 &b, const Vec2 &c) {
  const float c1 = cross2(a, b, p);
  const float c2 = cross2(b, c, p);
  const float c3 = cross2(c, a, p);
  const bool hasNeg = c1 < 0.0f || c2 < 0.0f || c3 < 0.0f;
  const bool hasPos = c1 > 0.0f || c2 > 0.0f || c3 > 0.0f;
  return !(hasNeg && hasPos);
}

bool pointInQuad(const Vec2 &p, const Vec2 &a, const Vec2 &b, const Vec2 &c, const Vec2 &d) {
  return pointInTriangle(p, a, b, c) || pointInTriangle(p, a, c, d);
}

Vec2 addVec(const Vec2 &a, const Vec2 &b) {
  return {a.x + b.x, a.y + b.y};
}

Vec2 scaleVec(const Vec2 &v, float s) {
  return {v.x * s, v.y * s};
}

Vec2 dirToRight(const Vec2 &forward) {
  return {-forward.y, forward.x};
}

int quantizeDirection8(float angle) {
  float wrapped = std::fmod(angle + PI, PI * 2.0f);
  if (wrapped < 0.0f) {
    wrapped += PI * 2.0f;
  }
  const int bucket = static_cast<int>(std::floor((wrapped + PI / 8.0f) / (PI / 4.0f)));
  return bucket % 8;
}

float directionAngle8(int bucket) {
  return -PI + static_cast<float>(bucket) * (PI * 0.25f);
}

Color rgb(int r, int g, int b, float a = 1.0f) {
  return {
    clampf(r / 255.0f, 0.0f, 1.0f),
    clampf(g / 255.0f, 0.0f, 1.0f),
    clampf(b / 255.0f, 0.0f, 1.0f),
    clampf(a, 0.0f, 1.0f)
  };
}

Color shade(const Color &c, float amount) {
  return {
    clampf(c.r + amount, 0.0f, 1.0f),
    clampf(c.g + amount, 0.0f, 1.0f),
    clampf(c.b + amount, 0.0f, 1.0f),
    c.a
  };
}

Color scaleColor(const Color &c, float scale) {
  return {
    clampf(c.r * scale, 0.0f, 1.0f),
    clampf(c.g * scale, 0.0f, 1.0f),
    clampf(c.b * scale, 0.0f, 1.0f),
    c.a
  };
}

void glColor(const Color &c) {
  glColor4f(c.r, c.g, c.b, c.a);
}

const std::unordered_map<char, std::array<uint8_t, 7>> FONT = {
  {' ', {0, 0, 0, 0, 0, 0, 0}},
  {'!', {4, 4, 4, 4, 4, 0, 4}},
  {'%', {17, 18, 4, 8, 19, 17, 0}},
  {'-', {0, 0, 31, 0, 0, 0, 0}},
  {':', {0, 4, 0, 0, 4, 0, 0}},
  {'0', {14, 17, 19, 21, 25, 17, 14}},
  {'1', {4, 12, 4, 4, 4, 4, 14}},
  {'2', {14, 17, 1, 2, 4, 8, 31}},
  {'3', {30, 1, 1, 14, 1, 1, 30}},
  {'4', {2, 6, 10, 18, 31, 2, 2}},
  {'5', {31, 16, 30, 1, 1, 17, 14}},
  {'6', {6, 8, 16, 30, 17, 17, 14}},
  {'7', {31, 1, 2, 4, 8, 8, 8}},
  {'8', {14, 17, 17, 14, 17, 17, 14}},
  {'9', {14, 17, 17, 15, 1, 2, 12}},
  {'A', {14, 17, 17, 31, 17, 17, 17}},
  {'B', {30, 17, 17, 30, 17, 17, 30}},
  {'C', {14, 17, 16, 16, 16, 17, 14}},
  {'D', {28, 18, 17, 17, 17, 18, 28}},
  {'E', {31, 16, 16, 30, 16, 16, 31}},
  {'F', {31, 16, 16, 30, 16, 16, 16}},
  {'G', {14, 17, 16, 23, 17, 17, 15}},
  {'H', {17, 17, 17, 31, 17, 17, 17}},
  {'I', {14, 4, 4, 4, 4, 4, 14}},
  {'J', {1, 1, 1, 1, 17, 17, 14}},
  {'K', {17, 18, 20, 24, 20, 18, 17}},
  {'L', {16, 16, 16, 16, 16, 16, 31}},
  {'M', {17, 27, 21, 21, 17, 17, 17}},
  {'N', {17, 25, 21, 19, 17, 17, 17}},
  {'O', {14, 17, 17, 17, 17, 17, 14}},
  {'P', {30, 17, 17, 30, 16, 16, 16}},
  {'Q', {14, 17, 17, 17, 21, 18, 13}},
  {'R', {30, 17, 17, 30, 20, 18, 17}},
  {'S', {15, 16, 16, 14, 1, 1, 30}},
  {'T', {31, 4, 4, 4, 4, 4, 4}},
  {'U', {17, 17, 17, 17, 17, 17, 14}},
  {'V', {17, 17, 17, 17, 17, 10, 4}},
  {'W', {17, 17, 17, 21, 21, 21, 10}},
  {'X', {17, 17, 10, 4, 10, 17, 17}},
  {'Y', {17, 17, 10, 4, 4, 4, 4}},
  {'Z', {31, 1, 2, 4, 8, 16, 31}}
};

class Game {
public:
  bool init() {
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
      std::cerr << "SDL_Init failed: " << SDL_GetError() << '\n';
      return false;
    }

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4);

    window = SDL_CreateWindow(
      "Friendly Freya | WASD/Arrows Move | Shift Run | E Eat | SPACE Vomit",
      SDL_WINDOWPOS_CENTERED,
      SDL_WINDOWPOS_CENTERED,
      windowW,
      windowH,
      SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE
    );

    if (!window) {
      std::cerr << "SDL_CreateWindow failed: " << SDL_GetError() << '\n';
      return false;
    }

    glContext = SDL_GL_CreateContext(window);
    if (!glContext) {
      std::cerr << "SDL_GL_CreateContext failed: " << SDL_GetError() << '\n';
      return false;
    }

    SDL_GL_MakeCurrent(window, glContext);
    SDL_GL_SetSwapInterval(1);

    glDisable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_CULL_FACE);
    glEnable(GL_MULTISAMPLE);
    glEnable(GL_LINE_SMOOTH);
    glEnable(GL_POINT_SMOOTH);
    glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
    glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);

    seedStaticScene();
    seedDetailTextures();
    seedActors();
    recalcProjection();
    initMaterials();
    return true;
  }

  void run() {
    uint64_t last = SDL_GetPerformanceCounter();

    while (running) {
      pressed.fill(false);
      handleEvents();

      const uint64_t now = SDL_GetPerformanceCounter();
      float dt = static_cast<float>(now - last) / static_cast<float>(SDL_GetPerformanceFrequency());
      last = now;
      dt = clampf(dt, 0.0f, 0.05f);

      update(dt);
      render();
      SDL_GL_SwapWindow(window);
    }
  }

  ~Game() {
    destroyMaterials();
    if (glContext) {
      SDL_GL_DeleteContext(glContext);
    }
    if (window) {
      SDL_DestroyWindow(window);
    }
    SDL_Quit();
  }

private:
  SDL_Window *window = nullptr;
  SDL_GLContext glContext = nullptr;
  int windowW = 1600;
  int windowH = 920;
  bool running = true;

  float tileW = 68.0f;
  float tileH = 34.0f;
  float originX = 0.0f;
  float originY = 0.0f;
  float cameraX = MAP_W * 0.5f;
  float cameraY = MAP_H * 0.5f;

  float worldTime = 0.0f;
  float poopSpawnTimer = 4.2f;

  std::array<bool, SDL_NUM_SCANCODES> keys{};
  std::array<bool, SDL_NUM_SCANCODES> pressed{};

  std::vector<Building> buildings;
  std::vector<Tree> trees;
  std::vector<Shrub> shrubs;
  std::vector<StreetLight> streetLights;
  std::vector<RectArea> roadAreas;
  std::vector<RectArea> sidewalkAreas;
  std::vector<RectArea> alleyAreas;
  std::vector<RectArea> alleyShoulderAreas;
  RectArea dogParkArea{78.0f, 2.4f, 94.0f, 14.0f};

  std::vector<Dog> dogs;
  Freya freya;
  std::vector<Poop> poops;
  std::vector<VomitPuddle> puddles;
  std::vector<BarkPulse> barkPulses;
  std::vector<FloatLabel> labels;

  std::vector<GrassPatch> grassPatches;
  std::vector<GrassBlade> grassBlades;
  std::vector<RoadScuff> roadScuffs;

  std::array<MaterialTexture, static_cast<size_t>(MaterialId::Count)> materials;
  float lastMaterialLightPhase = -1000.0f;

  std::mt19937 rng {std::random_device{}()};

  float hudNoPoopTimer = 0.0f;
  float hudEatTimer = 0.0f;
  float hudVomitReadyFlash = 0.0f;
  bool objectivePukeOnDogComplete = false;

  float randf(float minValue, float maxValue) {
    std::uniform_real_distribution<float> dist(minValue, maxValue);
    return dist(rng);
  }

  MaterialTexture &material(MaterialId id) {
    return materials[static_cast<size_t>(id)];
  }

  const MaterialTexture &material(MaterialId id) const {
    return materials[static_cast<size_t>(id)];
  }

  static float fract(float v) {
    return v - std::floor(v);
  }

  float noise2(float x, float y, float seed) const {
    return fract(std::sin(x * 12.9898f + y * 78.233f + seed * 11.173f) * 43758.5453f);
  }

  float smoothNoise(float x, float y, float seed) const {
    const float ix = std::floor(x);
    const float iy = std::floor(y);
    const float fx = x - ix;
    const float fy = y - iy;

    const float n00 = noise2(ix, iy, seed);
    const float n10 = noise2(ix + 1.0f, iy, seed);
    const float n01 = noise2(ix, iy + 1.0f, seed);
    const float n11 = noise2(ix + 1.0f, iy + 1.0f, seed);

    const float ux = fx * fx * (3.0f - 2.0f * fx);
    const float uy = fy * fy * (3.0f - 2.0f * fy);
    const float nx0 = lerpf(n00, n10, ux);
    const float nx1 = lerpf(n01, n11, ux);
    return lerpf(nx0, nx1, uy);
  }

  void generateMaterialData(MaterialId id) {
    MaterialTexture &mat = material(id);
    constexpr int S = MaterialTexture::SIZE;
    mat.baseRGB.assign(S * S * 3, 0);
    mat.normalRGB.assign(S * S * 3, 0);
    mat.litRGB.assign(S * S * 3, 0);

    std::vector<float> heights(S * S, 0.0f);
    const float seed = 11.0f + static_cast<float>(static_cast<int>(id) * 37);

    auto idx = [](int x, int y) {
      return y * MaterialTexture::SIZE + x;
    };

    for (int y = 0; y < S; y += 1) {
      for (int x = 0; x < S; x += 1) {
        const int i = idx(x, y);
        const int bi = i * 3;
        const float xf = static_cast<float>(x);
        const float yf = static_cast<float>(y);

        float h = 0.5f;
        Color c = rgb(128, 128, 128);

        if (id == MaterialId::Grass) {
          const float n1 = smoothNoise(xf * 0.045f, yf * 0.045f, seed);
          const float n2 = smoothNoise(xf * 0.11f + 17.0f, yf * 0.12f + 39.0f, seed + 4.7f);
          const float n3 = smoothNoise(xf * 0.29f, yf * 0.27f, seed + 9.2f);
          const float clump = smoothNoise((xf + n2 * 23.0f) * 0.028f, (yf + n1 * 21.0f) * 0.028f, seed + 12.1f);
          const float thatch = std::pow(std::max(0.0f, n3 - 0.52f), 2.0f);
          c = rgb(
            static_cast<int>(62 + n1 * 42 + clump * 18),
            static_cast<int>(134 + n1 * 88 + clump * 52 + thatch * 16),
            static_cast<int>(52 + n2 * 44 + clump * 18)
          );
          h = 0.46f + n1 * 0.31f + n2 * 0.22f + clump * 0.18f + thatch * 0.14f;
        } else if (id == MaterialId::Sidewalk) {
          const float n1 = smoothNoise(xf * 0.1f, yf * 0.1f, seed);
          const float n2 = smoothNoise(xf * 0.45f, yf * 0.41f, seed + 3.3f);
          const float tileX = std::fmod(xf, 16.0f);
          const float tileY = std::fmod(yf, 16.0f);
          const bool seam = tileX < 1.35f || tileY < 1.35f;
          const float crack = std::pow(std::max(0.0f, std::sin((xf * 0.31f + yf * 0.43f) + n2 * 1.2f)), 8.0f);
          c = seam
            ? rgb(144, 152, 154)
            : rgb(
                static_cast<int>(163 + n1 * 34),
                static_cast<int>(167 + n1 * 33),
                static_cast<int>(169 + n1 * 30)
              );
          h = (seam ? 0.3f : 0.56f) + n2 * 0.13f - crack * 0.22f;
        } else if (id == MaterialId::Road) {
          const float n1 = smoothNoise(xf * 0.11f, yf * 0.11f, seed);
          const float n2 = smoothNoise(xf * 0.41f, yf * 0.39f, seed + 8.1f);
          const float streak = std::sin(yf * 0.2f + n1 * 2.7f) * 0.5f + 0.5f;
          const float pebble = std::pow(std::max(0.0f, n2 - 0.55f), 2.0f);
          c = rgb(
            static_cast<int>(66 + n1 * 36 + streak * 10),
            static_cast<int>(71 + n1 * 30 + streak * 8),
            static_cast<int>(78 + n1 * 26 + streak * 8)
          );
          h = 0.48f + n1 * 0.2f + pebble * 0.3f;
        } else if (id == MaterialId::Brick) {
          const int row = y / 12;
          const int rowOffset = (row % 2) * 7;
          const int bx = (x + rowOffset) % 14;
          const int by = y % 12;
          const bool mortar = bx < 2 || by < 2;
          const float n1 = smoothNoise(xf * 0.17f, yf * 0.17f, seed + row * 0.31f);
          const float brickVar = smoothNoise(static_cast<float>(x / 14), static_cast<float>(row), seed + 17.0f);
          if (mortar) {
            c = rgb(198, 180, 160);
            h = 0.26f + n1 * 0.06f;
          } else {
            c = rgb(
              static_cast<int>(122 + brickVar * 38 + n1 * 16),
              static_cast<int>(66 + brickVar * 22),
              static_cast<int>(47 + brickVar * 14)
            );
            h = 0.58f + n1 * 0.24f;
          }
        } else {
          const int row = y / 9;
          const int rowShift = (row % 2) * 6;
          const int sx = (x + rowShift) % 12;
          const int sy = y % 9;
          const bool seam = sx < 2 || sy < 2;
          const float n1 = smoothNoise(xf * 0.15f, yf * 0.15f, seed + 1.4f);
          c = seam
            ? rgb(82, 72, 68)
            : rgb(
                static_cast<int>(72 + n1 * 26),
                static_cast<int>(64 + n1 * 19),
                static_cast<int>(61 + n1 * 15)
              );
          h = (seam ? 0.34f : 0.61f) + n1 * 0.16f;
        }

        heights[static_cast<size_t>(i)] = clampf(h, 0.0f, 1.0f);
        mat.baseRGB[static_cast<size_t>(bi + 0)] = static_cast<uint8_t>(clampf(c.r, 0.0f, 1.0f) * 255.0f);
        mat.baseRGB[static_cast<size_t>(bi + 1)] = static_cast<uint8_t>(clampf(c.g, 0.0f, 1.0f) * 255.0f);
        mat.baseRGB[static_cast<size_t>(bi + 2)] = static_cast<uint8_t>(clampf(c.b, 0.0f, 1.0f) * 255.0f);
      }
    }

    float normalStrength = 1.4f;
    if (id == MaterialId::Grass) {
      normalStrength = 2.1f;
    } else if (id == MaterialId::Road) {
      normalStrength = 1.8f;
    } else if (id == MaterialId::Brick) {
      normalStrength = 2.4f;
    } else if (id == MaterialId::Roof) {
      normalStrength = 2.0f;
    }

    for (int y = 0; y < S; y += 1) {
      for (int x = 0; x < S; x += 1) {
        const int xm1 = (x + S - 1) % S;
        const int xp1 = (x + 1) % S;
        const int ym1 = (y + S - 1) % S;
        const int yp1 = (y + 1) % S;

        const float hL = heights[static_cast<size_t>(idx(xm1, y))];
        const float hR = heights[static_cast<size_t>(idx(xp1, y))];
        const float hD = heights[static_cast<size_t>(idx(x, ym1))];
        const float hU = heights[static_cast<size_t>(idx(x, yp1))];

        float nx = (hL - hR) * normalStrength;
        float ny = (hD - hU) * normalStrength;
        float nz = 1.0f;
        const float invLen = 1.0f / std::sqrt(nx * nx + ny * ny + nz * nz + 1e-6f);
        nx *= invLen;
        ny *= invLen;
        nz *= invLen;

        const int bi = idx(x, y) * 3;
        mat.normalRGB[static_cast<size_t>(bi + 0)] = static_cast<uint8_t>((nx * 0.5f + 0.5f) * 255.0f);
        mat.normalRGB[static_cast<size_t>(bi + 1)] = static_cast<uint8_t>((ny * 0.5f + 0.5f) * 255.0f);
        mat.normalRGB[static_cast<size_t>(bi + 2)] = static_cast<uint8_t>((nz * 0.5f + 0.5f) * 255.0f);
      }
    }
  }

  void initMaterials() {
    for (int id = 0; id < static_cast<int>(MaterialId::Count); id += 1) {
      MaterialTexture &mat = materials[static_cast<size_t>(id)];
      generateMaterialData(static_cast<MaterialId>(id));
      glGenTextures(1, &mat.tex);
      glBindTexture(GL_TEXTURE_2D, mat.tex);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
      glTexImage2D(
        GL_TEXTURE_2D,
        0,
        GL_RGB,
        MaterialTexture::SIZE,
        MaterialTexture::SIZE,
        0,
        GL_RGB,
        GL_UNSIGNED_BYTE,
        mat.baseRGB.data()
      );
    }
    glBindTexture(GL_TEXTURE_2D, 0);
    updateMaterialLighting(true);
  }

  void destroyMaterials() {
    for (MaterialTexture &mat : materials) {
      if (mat.tex != 0) {
        glDeleteTextures(1, &mat.tex);
        mat.tex = 0;
      }
      mat.baseRGB.clear();
      mat.normalRGB.clear();
      mat.litRGB.clear();
    }
  }

  void updateMaterialLighting(bool force = false) {
    const float phase = worldTime * 0.42f;
    if (!force && std::fabs(phase - lastMaterialLightPhase) < 0.08f) {
      return;
    }
    lastMaterialLightPhase = phase;

    float lx = 0.45f + std::cos(phase * 0.7f) * 0.25f;
    float ly = -0.55f + std::sin(phase * 0.35f) * 0.12f;
    float lz = 0.72f;
    float len = std::sqrt(lx * lx + ly * ly + lz * lz);
    lx /= len;
    ly /= len;
    lz /= len;

    constexpr int S = MaterialTexture::SIZE;
    constexpr int PIXELS = S * S;

    for (int id = 0; id < static_cast<int>(MaterialId::Count); id += 1) {
      MaterialTexture &mat = materials[static_cast<size_t>(id)];
      if (mat.tex == 0) {
        continue;
      }

      if (mat.litRGB.size() != mat.baseRGB.size()) {
        mat.litRGB.resize(mat.baseRGB.size());
      }

      const MaterialId matId = static_cast<MaterialId>(id);
      float ambient = 0.42f;
      float diffuseStrength = 0.92f;
      float specStrength = 0.18f;
      float warmBase = 0.03f;
      float warmScale = 0.04f;
      float cool = 0.02f;
      float greenLift = 0.0f;

      if (matId == MaterialId::Grass) {
        ambient = 0.48f;
        diffuseStrength = 0.92f;
        specStrength = 0.12f;
        warmBase = 0.0f;
        warmScale = 0.015f;
        cool = 0.008f;
        greenLift = 0.13f;
      } else if (matId == MaterialId::Road) {
        ambient = 0.4f;
        diffuseStrength = 0.95f;
        specStrength = 0.16f;
        warmBase = 0.01f;
      } else if (matId == MaterialId::Roof) {
        ambient = 0.39f;
        diffuseStrength = 0.92f;
        specStrength = 0.22f;
        warmBase = 0.028f;
      }

      for (int i = 0; i < PIXELS; i += 1) {
        const int bi = i * 3;
        const float nx = (mat.normalRGB[static_cast<size_t>(bi + 0)] / 255.0f) * 2.0f - 1.0f;
        const float ny = (mat.normalRGB[static_cast<size_t>(bi + 1)] / 255.0f) * 2.0f - 1.0f;
        const float nz = (mat.normalRGB[static_cast<size_t>(bi + 2)] / 255.0f) * 2.0f - 1.0f;

        const float ndl = std::max(0.0f, nx * lx + ny * ly + nz * lz);
        const float spec = std::pow(std::max(0.0f, nz), 18.0f) * specStrength * (0.4f + ndl * 0.6f);
        const float light = ambient + ndl * diffuseStrength + spec;

        const float warm = warmBase + ndl * warmScale;
        const float br = (mat.baseRGB[static_cast<size_t>(bi + 0)] / 255.0f);
        const float bg = (mat.baseRGB[static_cast<size_t>(bi + 1)] / 255.0f);
        const float bb = (mat.baseRGB[static_cast<size_t>(bi + 2)] / 255.0f);

        mat.litRGB[static_cast<size_t>(bi + 0)] = static_cast<uint8_t>(clampf(br * (light + warm), 0.0f, 1.0f) * 255.0f);
        mat.litRGB[static_cast<size_t>(bi + 1)] = static_cast<uint8_t>(clampf(bg * (light + greenLift), 0.0f, 1.0f) * 255.0f);
        mat.litRGB[static_cast<size_t>(bi + 2)] = static_cast<uint8_t>(clampf(bb * (light - cool), 0.0f, 1.0f) * 255.0f);
      }

      glBindTexture(GL_TEXTURE_2D, mat.tex);
      glTexSubImage2D(
        GL_TEXTURE_2D,
        0,
        0,
        0,
        S,
        S,
        GL_RGB,
        GL_UNSIGNED_BYTE,
        mat.litRGB.data()
      );
    }
    glBindTexture(GL_TEXTURE_2D, 0);
  }

  Vec2 worldToScreen(float x, float y, float z = 0.0f) const {
    const float relX = x - cameraX;
    const float relY = y - cameraY;
    return {
      (relX - relY) * tileW * 0.5f + originX,
      (relX + relY) * tileH * 0.5f + originY - z
    };
  }

  float worldDirectionToScreenAngle(float dx, float dy) const {
    const float sx = dx - dy;
    const float sy = (dx + dy) * 0.5f;
    return std::atan2(sy, sx);
  }

  void recalcProjection() {
    const float widthScale = static_cast<float>(windowW) / (MAP_W * 1.55f);
    const float heightScale = static_cast<float>(windowH) / (MAP_H * 0.9f);
    const float zoom = 1.66f;
    tileW = clampf(std::min(widthScale, heightScale) * 2.0f * zoom, 78.0f, 132.0f);
    tileH = tileW * 0.5f;

    originX = windowW * 0.5f;
    originY = std::max(170.0f, windowH * 0.38f);

    glViewport(0, 0, windowW, windowH);
  }

  void setProjection2D() const {
    glViewport(0, 0, windowW, windowH);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0.0, static_cast<double>(windowW), static_cast<double>(windowH), 0.0, -1000.0, 1000.0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
  }

  void drawQuad(const Vec2 &a, const Vec2 &b, const Vec2 &c, const Vec2 &d, const Color &ca, const Color &cb, const Color &cc, const Color &cd) const {
    glBegin(GL_QUADS);
    glColor(ca);
    glVertex2f(a.x, a.y);
    glColor(cb);
    glVertex2f(b.x, b.y);
    glColor(cc);
    glVertex2f(c.x, c.y);
    glColor(cd);
    glVertex2f(d.x, d.y);
    glEnd();
  }

  void drawQuadSolid(const Vec2 &a, const Vec2 &b, const Vec2 &c, const Vec2 &d, const Color &color) const {
    drawQuad(a, b, c, d, color, color, color, color);
  }

  void bindMaterial(MaterialId id) const {
    const MaterialTexture &mat = material(id);
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, mat.tex);
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
  }

  void unbindMaterial() const {
    glBindTexture(GL_TEXTURE_2D, 0);
    glDisable(GL_TEXTURE_2D);
  }

  void drawTexturedQuad(
    const Vec2 &a,
    const Vec2 &b,
    const Vec2 &c,
    const Vec2 &d,
    const Vec2 &ta,
    const Vec2 &tb,
    const Vec2 &tc,
    const Vec2 &td,
    const Color &tint
  ) const {
    glColor(tint);
    glBegin(GL_QUADS);
    glTexCoord2f(ta.x, ta.y);
    glVertex2f(a.x, a.y);
    glTexCoord2f(tb.x, tb.y);
    glVertex2f(b.x, b.y);
    glTexCoord2f(tc.x, tc.y);
    glVertex2f(c.x, c.y);
    glTexCoord2f(td.x, td.y);
    glVertex2f(d.x, d.y);
    glEnd();
  }

  void drawTexturedTriangle(
    const Vec2 &a,
    const Vec2 &b,
    const Vec2 &c,
    const Vec2 &ta,
    const Vec2 &tb,
    const Vec2 &tc,
    const Color &tint
  ) const {
    glColor(tint);
    glBegin(GL_TRIANGLES);
    glTexCoord2f(ta.x, ta.y);
    glVertex2f(a.x, a.y);
    glTexCoord2f(tb.x, tb.y);
    glVertex2f(b.x, b.y);
    glTexCoord2f(tc.x, tc.y);
    glVertex2f(c.x, c.y);
    glEnd();
  }

  void drawTexturedWorldRect(
    float x0,
    float y0,
    float x1,
    float y1,
    float z,
    float uScale,
    float vScale,
    const Color &tint
  ) const {
    const Vec2 p00 = worldToScreen(x0, y0, z);
    const Vec2 p10 = worldToScreen(x1, y0, z);
    const Vec2 p11 = worldToScreen(x1, y1, z);
    const Vec2 p01 = worldToScreen(x0, y1, z);
    drawTexturedQuad(
      p00,
      p10,
      p11,
      p01,
      {0.0f, 0.0f},
      {(x1 - x0) * uScale, 0.0f},
      {(x1 - x0) * uScale, (y1 - y0) * vScale},
      {0.0f, (y1 - y0) * vScale},
      tint
    );
  }

  void drawTexturedWorldRectOffset(
    float x0,
    float y0,
    float x1,
    float y1,
    float z,
    float uScale,
    float vScale,
    float uOffset,
    float vOffset,
    const Color &tint
  ) const {
    const Vec2 p00 = worldToScreen(x0, y0, z);
    const Vec2 p10 = worldToScreen(x1, y0, z);
    const Vec2 p11 = worldToScreen(x1, y1, z);
    const Vec2 p01 = worldToScreen(x0, y1, z);
    drawTexturedQuad(
      p00,
      p10,
      p11,
      p01,
      {uOffset, vOffset},
      {uOffset + (x1 - x0) * uScale, vOffset},
      {uOffset + (x1 - x0) * uScale, vOffset + (y1 - y0) * vScale},
      {uOffset, vOffset + (y1 - y0) * vScale},
      tint
    );
  }

  void drawPolygon(const std::vector<Vec2> &points, const Color &color) const {
    if (points.size() < 3) {
      return;
    }
    glColor(color);
    glBegin(GL_POLYGON);
    for (const Vec2 &p : points) {
      glVertex2f(p.x, p.y);
    }
    glEnd();
  }

  void drawLine(const Vec2 &a, const Vec2 &b, const Color &color, float width = 1.0f) const {
    glLineWidth(width);
    glColor(color);
    glBegin(GL_LINES);
    glVertex2f(a.x, a.y);
    glVertex2f(b.x, b.y);
    glEnd();
  }

  void drawRect(float x, float y, float w, float h, const Color &color) const {
    glColor(color);
    glBegin(GL_QUADS);
    glVertex2f(x, y);
    glVertex2f(x + w, y);
    glVertex2f(x + w, y + h);
    glVertex2f(x, y + h);
    glEnd();
  }

  void drawRectBorder(float x, float y, float w, float h, const Color &color, float lineWidth = 1.0f) const {
    glLineWidth(lineWidth);
    glColor(color);
    glBegin(GL_LINE_LOOP);
    glVertex2f(x, y);
    glVertex2f(x + w, y);
    glVertex2f(x + w, y + h);
    glVertex2f(x, y + h);
    glEnd();
  }

  void drawEllipse(float cx, float cy, float rx, float ry, const Color &color, int segments = 34) const {
    glColor(color);
    glBegin(GL_TRIANGLE_FAN);
    glVertex2f(cx, cy);
    for (int i = 0; i <= segments; i += 1) {
      const float t = (static_cast<float>(i) / static_cast<float>(segments)) * PI * 2.0f;
      glVertex2f(cx + std::cos(t) * rx, cy + std::sin(t) * ry);
    }
    glEnd();
  }

  void drawEllipseOutline(float cx, float cy, float rx, float ry, const Color &color, float lineWidth = 2.0f, int segments = 44) const {
    glLineWidth(lineWidth);
    glColor(color);
    glBegin(GL_LINE_LOOP);
    for (int i = 0; i <= segments; i += 1) {
      const float t = (static_cast<float>(i) / static_cast<float>(segments)) * PI * 2.0f;
      glVertex2f(cx + std::cos(t) * rx, cy + std::sin(t) * ry);
    }
    glEnd();
  }

  void drawTriangle(const Vec2 &a, const Vec2 &b, const Vec2 &c, const Color &color) const {
    glColor(color);
    glBegin(GL_TRIANGLES);
    glVertex2f(a.x, a.y);
    glVertex2f(b.x, b.y);
    glVertex2f(c.x, c.y);
    glEnd();
  }

  void drawWorldRect(float x0, float y0, float x1, float y1, float z, const Color &c00, const Color &c10, const Color &c11, const Color &c01) const {
    const Vec2 p00 = worldToScreen(x0, y0, z);
    const Vec2 p10 = worldToScreen(x1, y0, z);
    const Vec2 p11 = worldToScreen(x1, y1, z);
    const Vec2 p01 = worldToScreen(x0, y1, z);
    drawQuad(p00, p10, p11, p01, c00, c10, c11, c01);
  }

  void drawWorldLine3D(float x0, float y0, float z0, float x1, float y1, float z1, const Color &color, float width = 1.0f) const {
    const Vec2 a = worldToScreen(x0, y0, z0);
    const Vec2 b = worldToScreen(x1, y1, z1);
    drawLine(a, b, color, width);
  }

  void drawWorldLine(float x0, float y0, float x1, float y1, const Color &color, float width = 1.0f) const {
    const Vec2 a = worldToScreen(x0, y0, 0.0f);
    const Vec2 b = worldToScreen(x1, y1, 0.0f);
    drawLine(a, b, color, width);
  }

  float localLightAt(float wx, float wy, float boost = 1.0f) const {
    const float dayCycle = 0.86f + std::sin(worldTime * 0.16f) * 0.06f;
    float light = dayCycle;

    light += std::sin(worldTime * 0.7f + wx * 0.2f + wy * 0.18f) * 0.02f;
    return clampf(light * boost, 0.5f, 1.55f);
  }

  void drawGlyph(char raw, float x, float y, float scale, const Color &color) const {
    const char c = static_cast<char>(std::toupper(static_cast<unsigned char>(raw)));
    const auto it = FONT.find(c);
    const std::array<uint8_t, 7> blank{0, 0, 0, 0, 0, 0, 0};
    const auto &bitmap = it == FONT.end() ? blank : it->second;

    for (int row = 0; row < 7; row += 1) {
      for (int col = 0; col < 5; col += 1) {
        if (bitmap[row] & (1 << (4 - col))) {
          drawRect(x + col * scale, y + row * scale, scale, scale, color);
        }
      }
    }
  }

  void drawText(const std::string &text, float x, float y, float scale, const Color &color) const {
    float cursor = x;
    for (const char c : text) {
      drawGlyph(c, cursor, y, scale, color);
      cursor += scale * 6.0f;
    }
  }

  RectArea makeArea(float x0, float y0, float x1, float y1) const {
    return {
      std::min(x0, x1),
      std::min(y0, y1),
      std::max(x0, x1),
      std::max(y0, y1)
    };
  }

  RectArea clipArea(const RectArea &a) const {
    return {
      clampf(a.x0, 0.0f, MAP_W),
      clampf(a.y0, 0.0f, MAP_H),
      clampf(a.x1, 0.0f, MAP_W),
      clampf(a.y1, 0.0f, MAP_H)
    };
  }

  bool validArea(const RectArea &a) const {
    return (a.x1 - a.x0) > 0.1f && (a.y1 - a.y0) > 0.1f;
  }

  bool areaContains(const RectArea &a, float x, float y) const {
    return x >= a.x0 && x <= a.x1 && y >= a.y0 && y <= a.y1;
  }

  bool inAnyArea(const std::vector<RectArea> &areas, float x, float y) const {
    for (const RectArea &a : areas) {
      if (areaContains(a, x, y)) {
        return true;
      }
    }
    return false;
  }

  bool areaIntersects(const RectArea &a, const RectArea &b, float pad = 0.0f) const {
    return !(a.x1 + pad <= b.x0 || a.x0 >= b.x1 + pad || a.y1 + pad <= b.y0 || a.y0 >= b.y1 + pad);
  }

  void addRoadArea(float x0, float y0, float x1, float y1) {
    const RectArea road = clipArea(makeArea(x0, y0, x1, y1));
    if (!validArea(road)) {
      return;
    }
    roadAreas.push_back(road);

    const float sidewalkWidth = 1.12f;
    const bool horizontal = (road.x1 - road.x0) > (road.y1 - road.y0);
    if (horizontal) {
      const RectArea top = clipArea(makeArea(road.x0, road.y0 - sidewalkWidth, road.x1, road.y0));
      const RectArea bottom = clipArea(makeArea(road.x0, road.y1, road.x1, road.y1 + sidewalkWidth));
      if (validArea(top)) {
        sidewalkAreas.push_back(top);
      }
      if (validArea(bottom)) {
        sidewalkAreas.push_back(bottom);
      }
    } else {
      const RectArea left = clipArea(makeArea(road.x0 - sidewalkWidth, road.y0, road.x0, road.y1));
      const RectArea right = clipArea(makeArea(road.x1, road.y0, road.x1 + sidewalkWidth, road.y1));
      if (validArea(left)) {
        sidewalkAreas.push_back(left);
      }
      if (validArea(right)) {
        sidewalkAreas.push_back(right);
      }
    }
  }

  void addAlleyArea(float x0, float y0, float x1, float y1) {
    const RectArea alley = clipArea(makeArea(x0, y0, x1, y1));
    if (!validArea(alley)) {
      return;
    }
    alleyAreas.push_back(alley);
  }

  bool inBuilding(float x, float y) const {
    for (const Building &b : buildings) {
      if (x > b.x - 0.18f && x < b.x + b.w + 0.18f && y > b.y - 0.18f && y < b.y + b.d + 0.18f) {
        return true;
      }
    }
    return false;
  }

  bool isWalkable(float x, float y) const {
    if (x < 0.7f || y < 0.7f || x > MAP_W - 0.7f || y > MAP_H - 0.7f) {
      return false;
    }
    if (inBuilding(x, y)) {
      return false;
    }
    return true;
  }

  enum class Surface {
    Grass,
    Sidewalk,
    Road
  };

  Surface surfaceAt(float x, float y) const {
    if (inAnyArea(roadAreas, x, y) || inAnyArea(alleyAreas, x, y)) {
      return Surface::Road;
    }
    if (inAnyArea(sidewalkAreas, x, y) || inAnyArea(alleyShoulderAreas, x, y)) {
      return Surface::Sidewalk;
    }
    return Surface::Grass;
  }

  bool inDogPark(float x, float y) const {
    return areaContains(dogParkArea, x, y);
  }

  bool inCameraRange(float x, float y, float padX = 0.0f, float padY = 0.0f) const {
    return std::fabs(x - cameraX) <= (22.0f + padX) && std::fabs(y - cameraY) <= (18.0f + padY);
  }

  Vec2 randomWalkablePoint(bool avoidRoad) {
    for (int i = 0; i < 360; i += 1) {
      Vec2 p{randf(1.0f, MAP_W - 1.0f), randf(1.0f, MAP_H - 1.0f)};
      if (!isWalkable(p.x, p.y)) {
        continue;
      }
      if (avoidRoad && surfaceAt(p.x, p.y) == Surface::Road) {
        continue;
      }
      return p;
    }
    return {MAP_W * 0.5f, MAP_H * 0.5f};
  }

  void addLabel(const std::string &text, const Vec2 &pos, const Color &color, float ttl) {
    labels.push_back({text, pos, 0.0f, ttl, color});
  }

  void addBarkPulse(const Vec2 &pos, const Color &color) {
    barkPulses.push_back({pos, 0.0f, 0.75f, 4.0f, 22.0f, color});
  }

  void seedStaticScene() {
    const std::array<Color, 4> walls = {
      rgb(160, 85, 56), rgb(133, 76, 66), rgb(168, 92, 63), rgb(125, 97, 76)
    };
    const std::array<Color, 4> roofs = {
      rgb(82, 72, 66), rgb(70, 62, 58), rgb(88, 78, 70), rgb(72, 63, 58)
    };

    const Color styleTrim = rgb(236, 223, 201);
    const Color styleGlass = rgb(189, 215, 240, 0.96f);

    buildings.clear();
    trees.clear();
    shrubs.clear();
    streetLights.clear();
    roadAreas.clear();
    sidewalkAreas.clear();
    alleyAreas.clear();
    alleyShoulderAreas.clear();
    dogParkArea = {78.0f, 2.8f, 94.0f, 15.0f};

    addRoadArea(21.8f, 0.0f, 25.6f, MAP_H);
    addRoadArea(45.8f, 0.0f, 49.6f, MAP_H);
    addRoadArea(69.8f, 0.0f, 73.6f, MAP_H);
    addRoadArea(0.0f, 17.8f, MAP_W, 21.6f);
    addRoadArea(0.0f, 41.6f, MAP_W, 45.4f);
    addRoadArea(0.0f, 65.6f, MAP_W, 69.4f);
    addRoadArea(73.6f, 28.5f, 89.0f, 32.3f);
    addRoadArea(6.0f, 52.5f, 21.8f, 56.3f);

    const std::vector<RectArea> blocks = {
      {2.2f, 2.2f, 20.2f, 16.0f}, {26.8f, 2.2f, 44.2f, 16.0f}, {50.8f, 2.2f, 68.2f, 16.0f}, {74.8f, 2.2f, 93.2f, 16.0f},
      {2.2f, 22.8f, 20.2f, 40.2f}, {26.8f, 22.8f, 44.2f, 40.2f}, {50.8f, 22.8f, 68.2f, 40.2f}, {74.8f, 22.8f, 93.2f, 40.2f},
      {2.2f, 46.8f, 20.2f, 64.2f}, {26.8f, 46.8f, 44.2f, 64.2f}, {50.8f, 46.8f, 68.2f, 64.2f}, {74.8f, 46.8f, 93.2f, 64.2f},
      {2.2f, 70.8f, 20.2f, 81.8f}, {26.8f, 70.8f, 44.2f, 81.8f}, {50.8f, 70.8f, 68.2f, 81.8f}, {74.8f, 70.8f, 93.2f, 81.8f}
    };

    auto nearestSideStreet = [&](const RectArea &block, float y, bool leftSide, float &roadEdgeX) {
      float bestGap = 1e9f;
      bool found = false;
      for (const RectArea &road : roadAreas) {
        const bool vertical = (road.x1 - road.x0) < (road.y1 - road.y0);
        if (!vertical || y < road.y0 - 0.3f || y > road.y1 + 0.3f) {
          continue;
        }
        if (leftSide && road.x1 <= block.x0 + 0.25f) {
          const float gap = block.x0 - road.x1;
          if (gap < bestGap) {
            bestGap = gap;
            roadEdgeX = road.x1;
            found = true;
          }
        } else if (!leftSide && road.x0 >= block.x1 - 0.25f) {
          const float gap = road.x0 - block.x1;
          if (gap < bestGap) {
            bestGap = gap;
            roadEdgeX = road.x0;
            found = true;
          }
        }
      }
      return found;
    };

    auto nearestCrossStreet = [&](const RectArea &block, float x, bool topSide, float &roadEdgeY) {
      float bestGap = 1e9f;
      bool found = false;
      for (const RectArea &road : roadAreas) {
        const bool horizontal = (road.x1 - road.x0) > (road.y1 - road.y0);
        if (!horizontal || x < road.x0 - 0.3f || x > road.x1 + 0.3f) {
          continue;
        }
        if (topSide && road.y1 <= block.y0 + 0.25f) {
          const float gap = block.y0 - road.y1;
          if (gap < bestGap) {
            bestGap = gap;
            roadEdgeY = road.y1;
            found = true;
          }
        } else if (!topSide && road.y0 >= block.y1 - 0.25f) {
          const float gap = road.y0 - block.y1;
          if (gap < bestGap) {
            bestGap = gap;
            roadEdgeY = road.y0;
            found = true;
          }
        }
      }
      return found;
    };

    for (const RectArea &block : blocks) {
      if (areaIntersects(block, dogParkArea, 0.35f)) {
        continue;
      }
      const float midY = (block.y0 + block.y1) * 0.5f;
      const float midX = (block.x0 + block.x1) * 0.5f;
      const float connectorHalf = model::kBuildingModel.alleyConnectorHalfWidth;
      const float alleyHalf = model::kBuildingModel.alleyHalfWidth;
      const float alleyInset = model::kBuildingModel.alleyEdgeInset;
      addAlleyArea(block.x0 + alleyInset, midY - alleyHalf, block.x1 - alleyInset, midY + alleyHalf);

      float leftRoadEdgeX = block.x0;
      float rightRoadEdgeX = block.x1;
      const bool leftConnected = nearestSideStreet(block, midY, true, leftRoadEdgeX);
      const bool rightConnected = nearestSideStreet(block, midY, false, rightRoadEdgeX);
      if (leftConnected) {
        addAlleyArea(leftRoadEdgeX, midY - connectorHalf, block.x0 + alleyInset, midY + connectorHalf);
      }
      if (rightConnected) {
        addAlleyArea(block.x1 - alleyInset, midY - connectorHalf, rightRoadEdgeX, midY + connectorHalf);
      }
      if (!leftConnected && !rightConnected) {
        float topRoadEdgeY = block.y0;
        float bottomRoadEdgeY = block.y1;
        const bool topConnected = nearestCrossStreet(block, midX, true, topRoadEdgeY);
        const bool bottomConnected = nearestCrossStreet(block, midX, false, bottomRoadEdgeY);
        if (topConnected) {
          addAlleyArea(midX - connectorHalf, topRoadEdgeY, midX + connectorHalf, block.y0 + alleyInset);
        }
        if (bottomConnected) {
          addAlleyArea(midX - connectorHalf, block.y1 - alleyInset, midX + connectorHalf, bottomRoadEdgeY);
        }
      }

      if (((static_cast<int>(std::floor(block.x0)) / 2) % 2) == 0) {
        addAlleyArea(
          midX - model::kBuildingModel.branchHalfWidth,
          block.y0 + model::kBuildingModel.streetSideSetback,
          midX + model::kBuildingModel.branchHalfWidth,
          block.y1 - model::kBuildingModel.streetSideSetback
        );
      }
    }

    // Concrete shoulders suppress grass right along alleys and behind buildings.
    for (const RectArea &alley : alleyAreas) {
      const bool horizontal = (alley.x1 - alley.x0) > (alley.y1 - alley.y0);
      const float shoulder = 0.28f;
      if (horizontal) {
        const RectArea top = clipArea(makeArea(alley.x0, alley.y0 - shoulder, alley.x1, alley.y0));
        const RectArea bottom = clipArea(makeArea(alley.x0, alley.y1, alley.x1, alley.y1 + shoulder));
        if (validArea(top)) {
          alleyShoulderAreas.push_back(top);
        }
        if (validArea(bottom)) {
          alleyShoulderAreas.push_back(bottom);
        }
      } else {
        const RectArea left = clipArea(makeArea(alley.x0 - shoulder, alley.y0, alley.x0, alley.y1));
        const RectArea right = clipArea(makeArea(alley.x1, alley.y0, alley.x1 + shoulder, alley.y1));
        if (validArea(left)) {
          alleyShoulderAreas.push_back(left);
        }
        if (validArea(right)) {
          alleyShoulderAreas.push_back(right);
        }
      }
    }

    int blockIndex = 0;
    for (const RectArea &block : blocks) {
      if (areaIntersects(block, dogParkArea, 0.35f)) {
        blockIndex += 1;
        continue;
      }
      auto overlapsAlley = [&](float bx, float by, float bw, float bd) {
        const RectArea candidate = makeArea(bx, by, bx + bw, by + bd);
        for (const RectArea &alley : alleyAreas) {
          if (areaIntersects(candidate, alley, 0.03f)) {
            return true;
          }
        }
        return false;
      };
      const float midY = (block.y0 + block.y1) * 0.5f;
      const float alleyY0 = midY - model::kBuildingModel.alleyHalfWidth;
      const float alleyY1 = midY + model::kBuildingModel.alleyHalfWidth;
      const float nearGap = model::kBuildingModel.alleyNearBuildingGap;
      const float streetSetback = model::kBuildingModel.streetSideSetback;
      const float blockW = block.x1 - block.x0;
      const int cols = std::max(2, static_cast<int>(std::floor(blockW / 6.6f)));
      const float stride = (blockW - 1.4f) / static_cast<float>(cols);
      for (int c = 0; c < cols; c += 1) {
        const bool lowRiseNorth = ((blockIndex + c) % 3 == 0) || randf(0.0f, 1.0f) < 0.24f;
        const bool lowRiseSouth = ((blockIndex + c + 1) % 4 == 0) || randf(0.0f, 1.0f) < 0.2f;
        const float w = randf(4.6f, 6.1f);
        const float dNorth = lowRiseNorth ? randf(3.9f, 4.8f) : randf(4.4f, 5.4f);
        const float dSouth = lowRiseSouth ? randf(3.9f, 4.8f) : randf(4.4f, 5.4f);
        const float x = clampf(block.x0 + 0.6f + c * stride + randf(-0.18f, 0.18f), block.x0 + 0.3f, block.x1 - w - 0.3f);
        const float northYMax = alleyY0 - dNorth - nearGap;
        const float northYMin = block.y0 + streetSetback;
        if (northYMax >= northYMin) {
          const int style = static_cast<int>(buildings.size()) % static_cast<int>(walls.size());
          const float lowH = randf(56.0f, 86.0f);
          const float highH = randf(124.0f, 172.0f);
          const float northY = clampf(northYMax + randf(-0.06f, 0.04f), northYMin, northYMax);
          if (!overlapsAlley(x, northY, w, dNorth)) {
            buildings.push_back({
              x,
              northY,
              w,
              dNorth,
              lowRiseNorth ? lowH : highH,
              walls[static_cast<size_t>(style)],
              roofs[static_cast<size_t>(style)],
              styleTrim,
              styleGlass,
              BuildingFront::North
            });
          }
        }

        const float southYMin = alleyY1 + nearGap;
        const float southYMax = block.y1 - dSouth - streetSetback;
        if (southYMax >= southYMin) {
          const int style2 = static_cast<int>(buildings.size()) % static_cast<int>(walls.size());
          const float lowHBack = randf(54.0f, 84.0f);
          const float highHBack = randf(124.0f, 170.0f);
          const float southY = clampf(southYMin + randf(-0.04f, 0.06f), southYMin, southYMax);
          if (!overlapsAlley(x + randf(-0.1f, 0.1f), southY, w, dSouth)) {
            buildings.push_back({
            x + randf(-0.15f, 0.15f),
            southY,
            w,
            dSouth,
            lowRiseSouth ? lowHBack : highHBack,
            walls[static_cast<size_t>(style2)],
            roofs[static_cast<size_t>(style2)],
            styleTrim,
            styleGlass,
            BuildingFront::South
            });
          }
        }
      }
      blockIndex += 1;
    }

    for (int i = 0; i < 280; i += 1) {
      for (int tries = 0; tries < 10; tries += 1) {
        const float x = randf(1.0f, MAP_W - 1.0f);
        const float y = randf(1.0f, MAP_H - 1.0f);
        if (surfaceAt(x, y) != Surface::Grass || inBuilding(x, y) || inDogPark(x, y)) {
          continue;
        }
        trees.push_back({x, y, randf(0.85f, 1.28f)});
        break;
      }
    }

    for (int i = 0; i < 300; i += 1) {
      for (int tries = 0; tries < 10; tries += 1) {
        const float x = randf(1.0f, MAP_W - 1.0f);
        const float y = randf(1.0f, MAP_H - 1.0f);
        if (surfaceAt(x, y) != Surface::Grass || inBuilding(x, y) || inDogPark(x, y)) {
          continue;
        }
        shrubs.push_back({x, y, randf(0.72f, 1.08f)});
        break;
      }
    }

    for (const RectArea &road : roadAreas) {
      const bool horizontal = (road.x1 - road.x0) > (road.y1 - road.y0);
      if (horizontal) {
        const float yTop = clampf(road.y0 - 0.42f, 0.5f, MAP_H - 0.5f);
        const float yBottom = clampf(road.y1 + 0.42f, 0.5f, MAP_H - 0.5f);
        for (float x = road.x0 + 2.4f; x < road.x1 - 2.0f; x += 10.4f) {
          streetLights.push_back({x, yTop});
          streetLights.push_back({x + 5.1f, yBottom});
        }
      } else {
        const float xLeft = clampf(road.x0 - 0.42f, 0.5f, MAP_W - 0.5f);
        const float xRight = clampf(road.x1 + 0.42f, 0.5f, MAP_W - 0.5f);
        for (float y = road.y0 + 2.5f; y < road.y1 - 2.0f; y += 10.6f) {
          streetLights.push_back({xLeft, y});
          streetLights.push_back({xRight, y + 4.8f});
        }
      }
    }
  }

  void seedDetailTextures() {
    grassPatches.clear();
    grassBlades.clear();
    roadScuffs.clear();

    for (int i = 0; i < 1500; i += 1) {
      const Vec2 p{randf(0.9f, MAP_W - 0.9f), randf(0.9f, MAP_H - 0.9f)};
      if (surfaceAt(p.x, p.y) != Surface::Grass || inBuilding(p.x, p.y)) {
        continue;
      }
      grassPatches.push_back({p, randf(0.08f, 0.42f), randf(-0.14f, 0.14f)});
    }

    for (int i = 0; i < 5600; i += 1) {
      const Vec2 p{randf(0.9f, MAP_W - 0.9f), randf(0.9f, MAP_H - 0.9f)};
      if (surfaceAt(p.x, p.y) != Surface::Grass || inBuilding(p.x, p.y)) {
        continue;
      }
      const float parkTrim = inDogPark(p.x, p.y) ? 0.7f : 1.0f;
      grassBlades.push_back({
        p,
        randf(2.8f, 7.4f) * parkTrim,
        randf(-0.08f, 0.08f),
        randf(-0.08f, 0.08f),
        randf(0.0f, PI * 2.0f),
        randf(-0.09f, 0.09f)
      });
    }

    for (const RectArea &road : roadAreas) {
      const bool horizontal = (road.x1 - road.x0) > (road.y1 - road.y0);
      const float area = (road.x1 - road.x0) * (road.y1 - road.y0);
      const int count = std::max(6, static_cast<int>(std::round(area * 0.18f)));
      for (int i = 0; i < count; i += 1) {
        roadScuffs.push_back({
          {
            randf(road.x0 + 0.25f, road.x1 - 0.25f),
            randf(road.y0 + 0.25f, road.y1 - 0.25f)
          },
          randf(0.3f, 1.35f),
          randf(0.03f, 0.14f),
          horizontal ? 0.0f : PI * 0.5f
        });
      }
    }

    for (const RectArea &alley : alleyAreas) {
      const bool horizontal = (alley.x1 - alley.x0) > (alley.y1 - alley.y0);
      const float area = (alley.x1 - alley.x0) * (alley.y1 - alley.y0);
      const int count = std::max(4, static_cast<int>(std::round(area * 0.22f)));
      for (int i = 0; i < count; i += 1) {
        roadScuffs.push_back({
          {
            randf(alley.x0 + 0.12f, alley.x1 - 0.12f),
            randf(alley.y0 + 0.12f, alley.y1 - 0.12f)
          },
          randf(0.16f, 0.75f),
          randf(0.04f, 0.18f),
          horizontal ? 0.0f : PI * 0.5f
        });
      }
    }
  }

  void seedActors() {
    freya.pos = {47.6f, 43.2f};
    freya.facing = -PI * 0.5f;
    freya.screenFacing = -PI * 0.5f;
    cameraX = freya.pos.x;
    cameraY = freya.pos.y;

    dogs.clear();
    poops.clear();
    puddles.clear();
    barkPulses.clear();
    labels.clear();
    objectivePukeOnDogComplete = false;

    const std::array<Color, 6> dogPalette = {
      rgb(42, 40, 37), rgb(90, 71, 56), rgb(205, 192, 171),
      rgb(132, 115, 98), rgb(224, 219, 207), rgb(119, 106, 92)
    };

    for (int i = 0; i < 12; i += 1) {
      Vec2 p = randomWalkablePoint(true);
      const float facing = randf(0.0f, PI * 2.0f);
      dogs.push_back({
        p,
        facing,
        worldDirectionToScreenAngle(std::cos(facing), std::sin(facing)),
        randf(1.0f, 1.85f),
        randf(0.7f, 2.8f),
        randf(0.4f, 1.2f),
        0.0f,
        randf(0.96f, 1.14f),
        randf(0.9f, 1.12f),
        randf(0.15f, 1.0f),
        randf(0.9f, 1.16f),
        randf(0.86f, 1.08f),
        dogPalette[static_cast<size_t>(i) % dogPalette.size()]
      });
    }

    for (int i = 0; i < 24; i += 1) {
      spawnPoop();
    }
  }

  void spawnPoop() {
    Vec2 p = randomWalkablePoint(true);
    if (surfaceAt(p.x, p.y) == Surface::Road) {
      return;
    }
    for (const Poop &poop : poops) {
      if (distSq(poop.pos, p) < 1.15f) {
        return;
      }
    }
    poops.push_back({p, randf(0.0f, PI * 2.0f)});
  }

  void handleEvents() {
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
      switch (event.type) {
        case SDL_QUIT:
          running = false;
          break;
        case SDL_WINDOWEVENT:
          if (event.window.event == SDL_WINDOWEVENT_RESIZED || event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED) {
            windowW = std::max(640, event.window.data1);
            windowH = std::max(480, event.window.data2);
            recalcProjection();
          }
          break;
        case SDL_KEYDOWN:
          if (!event.key.repeat) {
            keys[event.key.keysym.scancode] = true;
            pressed[event.key.keysym.scancode] = true;
          }
          break;
        case SDL_KEYUP:
          keys[event.key.keysym.scancode] = false;
          break;
        default:
          break;
      }
    }
  }

  void update(float dt) {
    worldTime += dt;
    hudNoPoopTimer = std::max(0.0f, hudNoPoopTimer - dt);
    hudEatTimer = std::max(0.0f, hudEatTimer - dt);

    updateFreya(dt);
    updateDogs(dt);
    handleActions();
    updatePoops(dt);
    updatePuddles(dt);
    updateBarksAndLabels(dt);
    updateCamera(dt);
  }

  void updateCamera(float dt) {
    const float lookAhead = 0.9f;
    const float targetX = freya.pos.x + std::cos(freya.facing) * lookAhead;
    const float targetY = freya.pos.y + std::sin(freya.facing) * lookAhead;
    const float follow = clampf(dt * 5.6f, 0.0f, 1.0f);
    cameraX = lerpf(cameraX, targetX, follow);
    cameraY = lerpf(cameraY, targetY, follow);
  }

  void updateFreya(float dt) {
    freya.hunger = clampf(freya.hunger + dt * 2.8f, 0.0f, 100.0f);
    freya.social = clampf(freya.social - dt * 1.15f, 0.0f, 100.0f);

    if (freya.vomitingTimer > 0.0f) {
      freya.vomitingTimer = std::max(0.0f, freya.vomitingTimer - dt);
      freya.step += dt * 6.2f;
      return;
    }

    int sx = 0;
    int sy = 0;

    if (keys[SDL_SCANCODE_A] || keys[SDL_SCANCODE_LEFT]) {
      sx -= 1;
    }
    if (keys[SDL_SCANCODE_D] || keys[SDL_SCANCODE_RIGHT]) {
      sx += 1;
    }
    if (keys[SDL_SCANCODE_W] || keys[SDL_SCANCODE_UP]) {
      sy -= 1;
    }
    if (keys[SDL_SCANCODE_S] || keys[SDL_SCANCODE_DOWN]) {
      sy += 1;
    }

    if (sx == 0 && sy == 0) {
      freya.step += dt * 2.4f;
      return;
    }

    float moveX = static_cast<float>(sx + sy);
    float moveY = static_cast<float>(sy - sx);
    const float len = std::sqrt(moveX * moveX + moveY * moveY);
    if (len > 0.0001f) {
      moveX /= len;
      moveY /= len;
    }

    const float speedPenalty = freya.hunger * 0.0032f;
    const bool sprint = keys[SDL_SCANCODE_LSHIFT] || keys[SDL_SCANCODE_RSHIFT];
    const float sprintBoost = sprint ? 1.55f : 1.0f;
    const float speed = std::max(1.55f, freya.speed * (1.0f - speedPenalty) * sprintBoost);

    const float nx = freya.pos.x + moveX * speed * dt;
    const float ny = freya.pos.y + moveY * speed * dt;

    if (isWalkable(nx, freya.pos.y)) {
      freya.pos.x = nx;
    }
    if (isWalkable(freya.pos.x, ny)) {
      freya.pos.y = ny;
    }

    freya.facing = std::atan2(moveY, moveX);
    freya.screenFacing = worldDirectionToScreenAngle(moveX, moveY);
    freya.step += dt * (sprint ? 18.0f : 12.0f);
  }

  void updateDogs(float dt) {
    for (Dog &dog : dogs) {
      dog.wanderTimer -= dt;
      dog.barkCooldown -= dt;

      if (dog.wanderTimer <= 0.0f) {
        dog.wanderTimer = randf(0.9f, 2.8f);
        dog.facing = randf(0.0f, PI * 2.0f);
      }

      const float dx = std::cos(dog.facing);
      const float dy = std::sin(dog.facing);
      const float nx = dog.pos.x + dx * dog.speed * dt;
      const float ny = dog.pos.y + dy * dog.speed * dt;

      if (isWalkable(nx, ny)) {
        dog.pos.x = nx;
        dog.pos.y = ny;
      } else {
        dog.facing += PI * 0.72f + randf(0.0f, 0.58f);
      }

      dog.screenFacing = worldDirectionToScreenAngle(std::cos(dog.facing), std::sin(dog.facing));
      dog.step += dt * 8.7f;

      const float near = distSq(dog.pos, freya.pos);
      if (near < 3.4f) {
        freya.social = clampf(freya.social + dt * 22.0f, 0.0f, 100.0f);
        if (dog.barkCooldown <= 0.0f) {
          addBarkPulse(dog.pos, rgb(243, 243, 243, 0.85f));
          addBarkPulse(freya.pos, rgb(255, 223, 140, 0.88f));
          addLabel("WOOF!", dog.pos, rgb(250, 250, 250), 0.8f);
          addLabel("ARF!", freya.pos, rgb(255, 228, 145), 0.8f);
          dog.barkCooldown = randf(0.9f, 1.5f);
        }
      }
    }
  }

  void handleActions() {
    if (pressed[SDL_SCANCODE_E]) {
      tryEatPoop();
    }
    if (pressed[SDL_SCANCODE_SPACE]) {
      tryVomit();
    }
  }

  void tryEatPoop() {
    int bestIndex = -1;
    float bestDist = 1000000.0f;

    for (int i = 0; i < static_cast<int>(poops.size()); i += 1) {
      const float d = distSq(freya.pos, poops[static_cast<size_t>(i)].pos);
      if (d < bestDist) {
        bestDist = d;
        bestIndex = i;
      }
    }

    if (bestIndex < 0 || bestDist > 1.08f) {
      hudNoPoopTimer = 0.9f;
      addLabel("NO POOP", freya.pos, rgb(214, 234, 246), 0.9f);
      return;
    }

    poops.erase(poops.begin() + bestIndex);
    freya.hunger = clampf(freya.hunger - 11.0f, 0.0f, 100.0f);
    freya.vomit = clampf(freya.vomit + 28.0f, 0.0f, 100.0f);
    hudEatTimer = 0.8f;
    addLabel("YUM...", freya.pos, rgb(237, 200, 153), 1.0f);
  }

  bool vomitHitsAnyDog(const Vec2 &from, const Vec2 &to) {
    constexpr float hitRadius = 0.95f;
    const float hitRadiusSq = hitRadius * hitRadius;
    bool hit = false;
    for (Dog &dog : dogs) {
      if (distSqPointToSegment(dog.pos, from, to) <= hitRadiusSq) {
        hit = true;
        addBarkPulse(dog.pos, rgb(198, 231, 146, 0.88f));
        addLabel("EWW!", dog.pos, rgb(236, 246, 222), 0.95f);
      }
    }
    return hit;
  }

  void tryVomit() {
    if (freya.vomit < 100.0f) {
      addLabel("NOT READY", freya.pos, rgb(202, 226, 236), 0.9f);
      return;
    }

    const Vec2 from = freya.pos;
    const Vec2 to{
      freya.pos.x + std::cos(freya.facing) * 1.35f,
      freya.pos.y + std::sin(freya.facing) * 1.35f
    };
    const bool pukedOnDog = vomitHitsAnyDog(from, to);

    const Vec2 p{
      freya.pos.x + std::cos(freya.facing) * 0.42f,
      freya.pos.y + std::sin(freya.facing) * 0.42f
    };
    puddles.push_back({p, 24.0f});
    freya.vomit = 0.0f;
    freya.vomitingTimer = 0.65f;
    addLabel("BLEAARGH!", freya.pos, rgb(186, 232, 132), 1.2f);

    if (pukedOnDog && !objectivePukeOnDogComplete) {
      objectivePukeOnDogComplete = true;
      addLabel("OBJECTIVE COMPLETE!", freya.pos, rgb(221, 245, 154), 1.4f);
    }
  }

  void updatePoops(float dt) {
    poopSpawnTimer -= dt;
    if (poopSpawnTimer <= 0.0f) {
      poopSpawnTimer = randf(3.1f, 6.4f);
      if (poops.size() < 16) {
        spawnPoop();
      }
    }
  }

  void updatePuddles(float dt) {
    for (int i = static_cast<int>(puddles.size()) - 1; i >= 0; i -= 1) {
      puddles[static_cast<size_t>(i)].ttl -= dt;
      if (puddles[static_cast<size_t>(i)].ttl <= 0.0f) {
        puddles.erase(puddles.begin() + i);
      }
    }
  }

  void updateBarksAndLabels(float dt) {
    for (int i = static_cast<int>(barkPulses.size()) - 1; i >= 0; i -= 1) {
      barkPulses[static_cast<size_t>(i)].age += dt;
      if (barkPulses[static_cast<size_t>(i)].age >= barkPulses[static_cast<size_t>(i)].ttl) {
        barkPulses.erase(barkPulses.begin() + i);
      }
    }

    for (int i = static_cast<int>(labels.size()) - 1; i >= 0; i -= 1) {
      labels[static_cast<size_t>(i)].age += dt;
      if (labels[static_cast<size_t>(i)].age >= labels[static_cast<size_t>(i)].ttl) {
        labels.erase(labels.begin() + i);
      }
    }
  }

  void drawBackground() const {
    drawQuad(
      {0.0f, 0.0f},
      {static_cast<float>(windowW), 0.0f},
      {static_cast<float>(windowW), static_cast<float>(windowH)},
      {0.0f, static_cast<float>(windowH)},
      rgb(184, 217, 247),
      rgb(167, 210, 245),
      rgb(123, 158, 108),
      rgb(131, 165, 113)
    );

    drawEllipse(windowW * 0.22f, windowH * 0.1f, windowW * 0.16f, windowH * 0.05f, rgb(255, 255, 255, 0.35f));
    drawEllipse(windowW * 0.65f, windowH * 0.08f, windowW * 0.13f, windowH * 0.045f, rgb(255, 255, 255, 0.32f));
  }

  void drawStreetLightPools() const {
    return;
  }

  void drawVignette() const {
    const float w = static_cast<float>(windowW);
    const float h = static_cast<float>(windowH);
    const float ix = w * 0.18f;
    const float iy = h * 0.16f;

    drawQuad(
      {0.0f, 0.0f},
      {w, 0.0f},
      {w - ix, iy},
      {ix, iy},
      rgb(8, 14, 16, 0.38f),
      rgb(8, 14, 16, 0.38f),
      rgb(8, 14, 16, 0.0f),
      rgb(8, 14, 16, 0.0f)
    );
    drawQuad(
      {0.0f, h},
      {w, h},
      {w - ix, h - iy},
      {ix, h - iy},
      rgb(8, 14, 16, 0.44f),
      rgb(8, 14, 16, 0.44f),
      rgb(8, 14, 16, 0.0f),
      rgb(8, 14, 16, 0.0f)
    );
    drawQuad(
      {0.0f, 0.0f},
      {ix, iy},
      {ix, h - iy},
      {0.0f, h},
      rgb(8, 14, 16, 0.36f),
      rgb(8, 14, 16, 0.0f),
      rgb(8, 14, 16, 0.0f),
      rgb(8, 14, 16, 0.42f)
    );
    drawQuad(
      {w, 0.0f},
      {w, h},
      {w - ix, h - iy},
      {w - ix, iy},
      rgb(8, 14, 16, 0.36f),
      rgb(8, 14, 16, 0.42f),
      rgb(8, 14, 16, 0.0f),
      rgb(8, 14, 16, 0.0f)
    );
  }

  void drawGround() const {
    bindMaterial(MaterialId::Grass);
    drawTexturedWorldRectOffset(0.0f, 0.0f, MAP_W, MAP_H, 0.0f, 0.28f, 0.22f, 0.0f, 0.0f, rgb(214, 246, 190));
    drawTexturedWorldRectOffset(0.0f, 0.0f, MAP_W, MAP_H, 0.01f, 0.58f, 0.39f, 41.0f, 19.0f, rgb(148, 219, 120, 0.34f));
    unbindMaterial();

    bindMaterial(MaterialId::Sidewalk);
    for (const RectArea &sw : sidewalkAreas) {
      drawTexturedWorldRectOffset(sw.x0, sw.y0, sw.x1, sw.y1, 0.0f, 0.68f, 0.52f, sw.x0 * 0.7f, sw.y0 * 0.5f, rgb(236, 236, 236));
    }
    for (const RectArea &sw : alleyShoulderAreas) {
      drawTexturedWorldRectOffset(sw.x0, sw.y0, sw.x1, sw.y1, 0.0f, 0.76f, 0.58f, sw.x0 * 0.62f + 12.0f, sw.y0 * 0.53f + 8.0f, rgb(214, 214, 208));
    }
    unbindMaterial();

    bindMaterial(MaterialId::Road);
    for (const RectArea &road : roadAreas) {
      drawTexturedWorldRectOffset(road.x0, road.y0, road.x1, road.y1, 0.0f, 0.86f, 0.34f, road.x0 * 0.5f, road.y0 * 0.4f, rgb(210, 215, 220));
      drawTexturedWorldRectOffset(road.x0, road.y0, road.x1, road.y1, 0.01f, 1.13f, 0.57f, road.x0 * 0.9f + 31.0f, road.y0 * 0.75f + 11.0f, rgb(124, 132, 141, 0.18f));
    }
    for (const RectArea &alley : alleyAreas) {
      drawTexturedWorldRectOffset(alley.x0, alley.y0, alley.x1, alley.y1, 0.0f, 1.03f, 0.62f, alley.x0 * 1.1f + 17.0f, alley.y0 * 1.2f + 9.0f, rgb(167, 172, 176));
      drawTexturedWorldRectOffset(alley.x0, alley.y0, alley.x1, alley.y1, 0.01f, 1.42f, 0.94f, alley.x0 * 1.7f + 53.0f, alley.y0 * 1.9f + 21.0f, rgb(93, 100, 108, 0.2f));
    }
    unbindMaterial();

    for (const RectArea &road : roadAreas) {
      const bool horizontal = (road.x1 - road.x0) > (road.y1 - road.y0);
      if (horizontal) {
        drawWorldRect(road.x0, road.y0 - 0.06f, road.x1, road.y0 + 0.04f, 0.02f, rgb(213, 224, 224, 0.5f), rgb(213, 224, 224, 0.5f), rgb(193, 203, 203, 0.4f), rgb(193, 203, 203, 0.4f));
        drawWorldRect(road.x0, road.y1 - 0.04f, road.x1, road.y1 + 0.06f, 0.02f, rgb(213, 224, 224, 0.5f), rgb(213, 224, 224, 0.5f), rgb(193, 203, 203, 0.4f), rgb(193, 203, 203, 0.4f));
        const float mid = (road.y0 + road.y1) * 0.5f;
        for (float x = road.x0 + 1.1f; x < road.x1 - 0.8f; x += 2.6f) {
          drawWorldRect(x, mid - 0.09f, x + 1.1f, mid + 0.09f, 0.03f, rgb(214, 214, 191), rgb(214, 214, 191), rgb(201, 201, 178), rgb(201, 201, 178));
        }
      } else {
        drawWorldRect(road.x0 - 0.06f, road.y0, road.x0 + 0.04f, road.y1, 0.02f, rgb(213, 224, 224, 0.5f), rgb(213, 224, 224, 0.5f), rgb(193, 203, 203, 0.4f), rgb(193, 203, 203, 0.4f));
        drawWorldRect(road.x1 - 0.04f, road.y0, road.x1 + 0.06f, road.y1, 0.02f, rgb(213, 224, 224, 0.5f), rgb(213, 224, 224, 0.5f), rgb(193, 203, 203, 0.4f), rgb(193, 203, 203, 0.4f));
        const float mid = (road.x0 + road.x1) * 0.5f;
        for (float y = road.y0 + 1.1f; y < road.y1 - 0.8f; y += 2.6f) {
          drawWorldRect(mid - 0.09f, y, mid + 0.09f, y + 1.1f, 0.03f, rgb(214, 214, 191), rgb(214, 214, 191), rgb(201, 201, 178), rgb(201, 201, 178));
        }
      }
    }

    for (const RectArea &alley : alleyAreas) {
      const bool horizontal = (alley.x1 - alley.x0) > (alley.y1 - alley.y0);
      if (horizontal) {
        drawWorldRect(alley.x0, alley.y0 - 0.03f, alley.x1, alley.y0 + 0.02f, 0.02f, rgb(181, 188, 194, 0.28f), rgb(181, 188, 194, 0.28f), rgb(130, 138, 145, 0.2f), rgb(130, 138, 145, 0.2f));
        drawWorldRect(alley.x0, alley.y1 - 0.02f, alley.x1, alley.y1 + 0.03f, 0.02f, rgb(181, 188, 194, 0.28f), rgb(181, 188, 194, 0.28f), rgb(130, 138, 145, 0.2f), rgb(130, 138, 145, 0.2f));
      } else {
        drawWorldRect(alley.x0 - 0.03f, alley.y0, alley.x0 + 0.02f, alley.y1, 0.02f, rgb(181, 188, 194, 0.28f), rgb(181, 188, 194, 0.28f), rgb(130, 138, 145, 0.2f), rgb(130, 138, 145, 0.2f));
        drawWorldRect(alley.x1 - 0.02f, alley.y0, alley.x1 + 0.03f, alley.y1, 0.02f, rgb(181, 188, 194, 0.28f), rgb(181, 188, 194, 0.28f), rgb(130, 138, 145, 0.2f), rgb(130, 138, 145, 0.2f));
      }
    }

    for (const RectArea &alley : alleyAreas) {
      const bool horizontal = (alley.x1 - alley.x0) > (alley.y1 - alley.y0);
      if (horizontal) {
        for (float x = alley.x0 + 0.85f; x < alley.x1 - 0.85f; x += 2.6f) {
          if (!inCameraRange(x, (alley.y0 + alley.y1) * 0.5f, 2.8f, 2.8f)) {
            continue;
          }
          const float n = noise2(x * 0.9f, alley.y0 * 3.7f, 23.0f);
          const float apron = 0.22f + n * 0.2f;
          drawWorldRect(
            x - 0.22f, alley.y0 - (0.24f + apron), x + 0.22f, alley.y0 - 0.04f, 0.03f,
            rgb(171, 176, 181, 0.32f), rgb(171, 176, 181, 0.32f), rgb(125, 132, 138, 0.24f), rgb(125, 132, 138, 0.24f)
          );
          drawWorldRect(
            x - 0.22f, alley.y1 + 0.04f, x + 0.22f, alley.y1 + (0.24f + apron), 0.03f,
            rgb(171, 176, 181, 0.32f), rgb(171, 176, 181, 0.32f), rgb(125, 132, 138, 0.24f), rgb(125, 132, 138, 0.24f)
          );
          drawWorldLine(x - 0.32f, alley.y0 - 0.02f, x + 0.3f, alley.y0 + 0.02f, rgb(35, 44, 50, 0.16f), 1.0f);
          drawWorldLine(x + 0.31f, alley.y1 - 0.02f, x - 0.33f, alley.y1 + 0.02f, rgb(35, 44, 50, 0.16f), 1.0f);
        }
      } else {
        for (float y = alley.y0 + 0.85f; y < alley.y1 - 0.85f; y += 2.6f) {
          if (!inCameraRange((alley.x0 + alley.x1) * 0.5f, y, 2.8f, 2.8f)) {
            continue;
          }
          const float n = noise2(alley.x0 * 3.3f, y * 0.88f, 27.0f);
          const float apron = 0.22f + n * 0.2f;
          drawWorldRect(
            alley.x0 - (0.24f + apron), y - 0.22f, alley.x0 - 0.04f, y + 0.22f, 0.03f,
            rgb(171, 176, 181, 0.32f), rgb(171, 176, 181, 0.32f), rgb(125, 132, 138, 0.24f), rgb(125, 132, 138, 0.24f)
          );
          drawWorldRect(
            alley.x1 + 0.04f, y - 0.22f, alley.x1 + (0.24f + apron), y + 0.22f, 0.03f,
            rgb(171, 176, 181, 0.32f), rgb(171, 176, 181, 0.32f), rgb(125, 132, 138, 0.24f), rgb(125, 132, 138, 0.24f)
          );
          drawWorldLine(alley.x0 - 0.02f, y - 0.32f, alley.x0 + 0.02f, y + 0.3f, rgb(35, 44, 50, 0.16f), 1.0f);
          drawWorldLine(alley.x1 - 0.02f, y + 0.31f, alley.x1 + 0.02f, y - 0.33f, rgb(35, 44, 50, 0.16f), 1.0f);
        }
      }
    }

    for (const RectArea &sw : sidewalkAreas) {
      const bool horizontal = (sw.x1 - sw.x0) > (sw.y1 - sw.y0);
      if (horizontal) {
        for (float x = sw.x0 + 0.3f; x < sw.x1 - 0.2f; x += 1.3f) {
          drawWorldLine(x, sw.y0 + 0.03f, x + 0.12f, sw.y1 - 0.03f, rgb(91, 98, 101, 0.25f), 1.0f);
        }
      } else {
        for (float y = sw.y0 + 0.3f; y < sw.y1 - 0.2f; y += 1.3f) {
          drawWorldLine(sw.x0 + 0.03f, y, sw.x1 - 0.03f, y + 0.12f, rgb(91, 98, 101, 0.25f), 1.0f);
        }
      }
    }

    for (const GrassPatch &patch : grassPatches) {
      if (!inCameraRange(patch.pos.x, patch.pos.y, 3.0f, 3.0f)) {
        continue;
      }
      const Vec2 p = worldToScreen(patch.pos.x, patch.pos.y);
      const float sw = std::sin(worldTime * 0.8f + patch.pos.x * 0.62f + patch.pos.y * 0.35f) * 1.0f;
      const Color c = shade(rgb(99, 176, 79), patch.shade);
      drawEllipse(p.x + sw * 0.08f, p.y, tileW * patch.r * 0.23f, tileH * patch.r * 0.5f, c, 18);
      drawEllipse(p.x - 1.2f + sw * 0.12f, p.y - 1.0f, tileW * patch.r * 0.12f, tileH * patch.r * 0.25f, rgb(190, 236, 163, 0.25f), 14);
      drawEllipse(p.x + 0.9f + sw * 0.1f, p.y + 0.8f, tileW * patch.r * 0.1f, tileH * patch.r * 0.2f, rgb(68, 132, 57, 0.22f), 14);
    }

    // Thin 3D blades break up flat terrain and read as real grass in motion.
    for (const GrassBlade &blade : grassBlades) {
      const float dx = std::fabs(blade.pos.x - cameraX);
      const float dy = std::fabs(blade.pos.y - cameraY);
      if (dx > 18.0f || dy > 14.5f) {
        continue;
      }
      if ((dx > 12.0f || dy > 10.0f) && std::fmod(std::floor(blade.pos.x * 9.0f + blade.pos.y * 11.0f), 2.0f) > 0.5f) {
        continue;
      }
      const float windBase = std::sin(worldTime * 0.72f + blade.pos.x * 0.14f + blade.pos.y * 0.11f) * 0.09f;
      const float windGust = std::sin(worldTime * 1.08f + blade.swayPhase * 0.7f) * 0.03f;
      const float sway = windBase + windGust;
      const float h = blade.h * (0.92f + std::sin(worldTime * 0.42f + blade.swayPhase) * 0.04f);
      const float tx = blade.pos.x + blade.leanX * 0.58f + sway;
      const float ty = blade.pos.y + blade.leanY * 0.58f + sway * 0.28f;
      const Color dark = shade(rgb(52, 116, 46, 0.74f), blade.brightness);
      const Color lit = shade(rgb(103, 194, 84, 0.82f), blade.brightness * 0.5f);
      drawWorldLine3D(blade.pos.x, blade.pos.y, 0.0f, tx, ty, h, dark, 1.0f);
      drawWorldLine3D(blade.pos.x + 0.02f, blade.pos.y - 0.02f, 0.0f, tx + 0.03f, ty + 0.01f, h * 0.7f, lit, 0.8f);
    }

    for (const RoadScuff &scuff : roadScuffs) {
      if (!inCameraRange(scuff.pos.x, scuff.pos.y, 4.0f, 4.0f)) {
        continue;
      }
      const Vec2 a = worldToScreen(scuff.pos.x, scuff.pos.y);
      const Vec2 b = worldToScreen(scuff.pos.x + std::cos(scuff.angle) * scuff.len, scuff.pos.y + std::sin(scuff.angle) * scuff.len);
      drawLine(a, b, rgb(26, 33, 40, scuff.alpha), 1.3f);
    }

    for (const RectArea &road : roadAreas) {
      const bool horizontal = (road.x1 - road.x0) > (road.y1 - road.y0);
      if (horizontal) {
        for (float x = road.x0 + 0.2f; x < road.x1 - 0.2f; x += 1.25f) {
          if (!inCameraRange(x, road.y0, 3.0f, 3.0f)) {
            continue;
          }
          const float sway = std::sin(x * 0.8f) * 0.04f;
          drawWorldLine(x, road.y0 - 0.35f + sway, x + 0.04f, road.y0 - 0.08f + sway, rgb(58, 73, 52, 0.24f), 1.0f);
          drawWorldLine(x + 0.02f, road.y1 + 0.08f - sway, x - 0.03f, road.y1 + 0.34f - sway, rgb(58, 73, 52, 0.24f), 1.0f);
        }
        drawWorldRect(road.x0, road.y0 - 0.12f, road.x1, road.y0 + 0.16f, 0.04f, rgb(0, 0, 0, 0.05f), rgb(0, 0, 0, 0.08f), rgb(0, 0, 0, 0.08f), rgb(0, 0, 0, 0.05f));
        drawWorldRect(road.x0, road.y1 - 0.16f, road.x1, road.y1 + 0.12f, 0.04f, rgb(0, 0, 0, 0.08f), rgb(0, 0, 0, 0.05f), rgb(0, 0, 0, 0.05f), rgb(0, 0, 0, 0.08f));
      } else {
        for (float y = road.y0 + 0.2f; y < road.y1 - 0.2f; y += 1.25f) {
          if (!inCameraRange(road.x0, y, 3.0f, 3.0f)) {
            continue;
          }
          const float sway = std::sin(y * 0.8f) * 0.04f;
          drawWorldLine(road.x0 - 0.35f + sway, y, road.x0 - 0.08f + sway, y + 0.04f, rgb(58, 73, 52, 0.24f), 1.0f);
          drawWorldLine(road.x1 + 0.08f - sway, y + 0.02f, road.x1 + 0.34f - sway, y - 0.03f, rgb(58, 73, 52, 0.24f), 1.0f);
        }
        drawWorldRect(road.x0 - 0.12f, road.y0, road.x0 + 0.16f, road.y1, 0.04f, rgb(0, 0, 0, 0.05f), rgb(0, 0, 0, 0.08f), rgb(0, 0, 0, 0.08f), rgb(0, 0, 0, 0.05f));
        drawWorldRect(road.x1 - 0.16f, road.y0, road.x1 + 0.12f, road.y1, 0.04f, rgb(0, 0, 0, 0.08f), rgb(0, 0, 0, 0.05f), rgb(0, 0, 0, 0.05f), rgb(0, 0, 0, 0.08f));
      }
    }
  }

  void drawDogPark() const {
    drawWorldRect(
      dogParkArea.x0, dogParkArea.y0, dogParkArea.x1, dogParkArea.y1, 0.03f,
      rgb(90, 162, 74, 0.5f), rgb(90, 162, 74, 0.5f), rgb(78, 147, 66, 0.46f), rgb(78, 147, 66, 0.46f)
    );

    const float midX = (dogParkArea.x0 + dogParkArea.x1) * 0.5f;
    drawWorldRect(midX - 0.5f, dogParkArea.y0 + 1.5f, midX + 0.5f, dogParkArea.y1 - 1.5f, 0.04f, rgb(160, 133, 95, 0.5f), rgb(160, 133, 95, 0.5f), rgb(146, 120, 86, 0.46f), rgb(146, 120, 86, 0.46f));
    drawWorldRect(dogParkArea.x0 + 1.7f, dogParkArea.y0 + 5.1f, dogParkArea.x1 - 1.7f, dogParkArea.y0 + 6.2f, 0.04f, rgb(160, 133, 95, 0.48f), rgb(160, 133, 95, 0.48f), rgb(146, 120, 86, 0.44f), rgb(146, 120, 86, 0.44f));

    const float fenceH = 16.0f;
    auto drawFencePost = [&](float x, float y) {
      drawWorldLine3D(x, y, 0.0f, x, y, fenceH, rgb(108, 112, 104), 1.5f);
    };

    for (float x = dogParkArea.x0; x <= dogParkArea.x1 + 0.01f; x += 1.2f) {
      drawFencePost(x, dogParkArea.y0);
      drawFencePost(x, dogParkArea.y1);
    }
    for (float y = dogParkArea.y0; y <= dogParkArea.y1 + 0.01f; y += 1.2f) {
      drawFencePost(dogParkArea.x0, y);
      drawFencePost(dogParkArea.x1, y);
    }

    const float gateW = 1.5f;
    drawWorldLine3D(dogParkArea.x0 + 0.7f + gateW, dogParkArea.y1, 0.0f, dogParkArea.x1 - 0.7f, dogParkArea.y1, 0.0f, rgb(126, 130, 123, 0.75f), 1.0f);
    drawWorldLine3D(dogParkArea.x0, dogParkArea.y0, 8.0f, dogParkArea.x1, dogParkArea.y0, 8.0f, rgb(126, 130, 123, 0.72f), 1.0f);
    drawWorldLine3D(dogParkArea.x0, dogParkArea.y1, 8.0f, dogParkArea.x1, dogParkArea.y1, 8.0f, rgb(126, 130, 123, 0.72f), 1.0f);
    drawWorldLine3D(dogParkArea.x0, dogParkArea.y0, 8.0f, dogParkArea.x0, dogParkArea.y1, 8.0f, rgb(126, 130, 123, 0.72f), 1.0f);
    drawWorldLine3D(dogParkArea.x1, dogParkArea.y0, 8.0f, dogParkArea.x1, dogParkArea.y1, 8.0f, rgb(126, 130, 123, 0.72f), 1.0f);

    const Vec2 sign = worldToScreen(dogParkArea.x0 + 0.8f, dogParkArea.y0 + 0.8f, 18.0f);
    drawRect(sign.x - 16.0f, sign.y - 10.0f, 32.0f, 14.0f, rgb(52, 78, 56, 0.88f));
    drawRectBorder(sign.x - 16.0f, sign.y - 10.0f, 32.0f, 14.0f, rgb(179, 206, 175, 0.8f));
    drawText("DOG PARK", sign.x - 13.0f, sign.y - 7.0f, 1.1f, rgb(225, 241, 219, 0.95f));
  }

  void drawWindowX(float x, float y0, float y1, float z0, float z1, const Color &glass, const Color &frame, float insetDir = 1.0f) const {
    const Vec2 a = worldToScreen(x, y0, z0);
    const Vec2 b = worldToScreen(x, y1, z0);
    const Vec2 c = worldToScreen(x, y1, z1);
    const Vec2 d = worldToScreen(x, y0, z1);
    drawQuadSolid(a, b, c, d, frame);
    drawLine(a, b, shade(frame, -0.18f), 1.0f);
    drawLine(d, c, shade(frame, 0.06f), 1.0f);
    drawTriangle(a, worldToScreen(x, y0 + 0.08f, z0 + 8.0f), worldToScreen(x, y0, z0 + 7.5f), shade(frame, -0.13f));
    drawTriangle(b, worldToScreen(x, y1 - 0.08f, z0 + 8.0f), worldToScreen(x, y1, z0 + 7.5f), shade(frame, -0.13f));

    const float inset = 0.08f * insetDir;
    const Vec2 a2 = worldToScreen(x + inset, y0 + 0.06f, z0 + 1.4f);
    const Vec2 b2 = worldToScreen(x + inset, y1 - 0.06f, z0 + 1.4f);
    const Vec2 c2 = worldToScreen(x + inset, y1 - 0.11f, z1 - 1.9f);
    const Vec2 d2 = worldToScreen(x + inset, y0 + 0.11f, z1 - 1.9f);
    drawQuadSolid(a2, b2, c2, d2, glass);

    const float midY = (y0 + y1) * 0.5f;
    const Vec2 archFrame = worldToScreen(x + inset, midY, z1 - 1.0f);
    const Vec2 archGlass = worldToScreen(x + inset, midY, z1 - 1.6f);
    drawEllipse(archFrame.x, archFrame.y, 2.7f, 2.0f, shade(frame, 0.04f), 14);
    drawEllipse(archGlass.x, archGlass.y + 0.2f, 1.9f, 1.3f, shade(glass, 0.06f), 12);
    const Vec2 lowerFrame = worldToScreen(x + inset, midY, z0 + 1.8f);
    drawEllipse(lowerFrame.x, lowerFrame.y, 1.8f, 0.95f, shade(frame, -0.05f), 12);

    const Vec2 mullionTop = worldToScreen(x + inset, midY, z1 - 2.6f);
    const Vec2 mullionBottom = worldToScreen(x + inset, midY, z0 + 1.7f);
    drawLine(mullionTop, mullionBottom, rgb(229, 230, 218, 0.45f), 1.0f);
    drawLine(worldToScreen(x + inset, y0 + 0.11f, (z0 + z1) * 0.5f), worldToScreen(x + inset, y1 - 0.11f, (z0 + z1) * 0.5f), rgb(229, 230, 218, 0.35f), 1.0f);
  }

  void drawWindowY(float y, float x0, float x1, float z0, float z1, const Color &glass, const Color &frame, float insetDir = 1.0f) const {
    const Vec2 a = worldToScreen(x0, y, z0);
    const Vec2 b = worldToScreen(x1, y, z0);
    const Vec2 c = worldToScreen(x1, y, z1);
    const Vec2 d = worldToScreen(x0, y, z1);
    drawQuadSolid(a, b, c, d, frame);
    drawLine(a, b, shade(frame, -0.18f), 1.0f);
    drawLine(d, c, shade(frame, 0.06f), 1.0f);
    drawTriangle(a, worldToScreen(x0 + 0.08f, y, z0 + 8.0f), worldToScreen(x0, y, z0 + 7.5f), shade(frame, -0.13f));
    drawTriangle(b, worldToScreen(x1 - 0.08f, y, z0 + 8.0f), worldToScreen(x1, y, z0 + 7.5f), shade(frame, -0.13f));

    const float inset = 0.08f * insetDir;
    const Vec2 a2 = worldToScreen(x0 + 0.06f, y + inset, z0 + 1.4f);
    const Vec2 b2 = worldToScreen(x1 - 0.06f, y + inset, z0 + 1.4f);
    const Vec2 c2 = worldToScreen(x1 - 0.11f, y + inset, z1 - 1.9f);
    const Vec2 d2 = worldToScreen(x0 + 0.11f, y + inset, z1 - 1.9f);
    drawQuadSolid(a2, b2, c2, d2, glass);

    const float midX = (x0 + x1) * 0.5f;
    const Vec2 archFrame = worldToScreen(midX, y + inset, z1 - 1.0f);
    const Vec2 archGlass = worldToScreen(midX, y + inset, z1 - 1.6f);
    drawEllipse(archFrame.x, archFrame.y, 2.7f, 2.0f, shade(frame, 0.04f), 14);
    drawEllipse(archGlass.x, archGlass.y + 0.2f, 1.9f, 1.3f, shade(glass, 0.06f), 12);
    const Vec2 lowerFrame = worldToScreen(midX, y + inset, z0 + 1.8f);
    drawEllipse(lowerFrame.x, lowerFrame.y, 1.8f, 0.95f, shade(frame, -0.05f), 12);

    const Vec2 mullionTop = worldToScreen(midX, y + inset, z1 - 2.6f);
    const Vec2 mullionBottom = worldToScreen(midX, y + inset, z0 + 1.7f);
    drawLine(mullionTop, mullionBottom, rgb(229, 230, 218, 0.45f), 1.0f);
    drawLine(worldToScreen(x0 + 0.11f, y + inset, (z0 + z1) * 0.5f), worldToScreen(x1 - 0.11f, y + inset, (z0 + z1) * 0.5f), rgb(229, 230, 218, 0.35f), 1.0f);
  }

  void drawBuilding(const Building &b) const {
    const Vec2 A = worldToScreen(b.x, b.y, 0.0f);
    const Vec2 B = worldToScreen(b.x + b.w, b.y, 0.0f);
    const Vec2 C = worldToScreen(b.x + b.w, b.y + b.d, 0.0f);
    const Vec2 D = worldToScreen(b.x, b.y + b.d, 0.0f);

    const Vec2 A2 = worldToScreen(b.x, b.y, b.h);
    const Vec2 B2 = worldToScreen(b.x + b.w, b.y, b.h);
    const Vec2 C2 = worldToScreen(b.x + b.w, b.y + b.d, b.h);
    const Vec2 D2 = worldToScreen(b.x, b.y + b.d, b.h);
    const float buildingLight = localLightAt(b.x + b.w * 0.5f, b.y + b.d * 0.5f, 1.02f);

    drawQuadSolid(
      {C.x, C.y},
      {D.x, D.y},
      {D.x + tileW * 1.04f, D.y + tileH * 0.56f},
      {C.x + tileW * 1.04f, C.y + tileH * 0.56f},
      rgb(9, 19, 13, 0.24f)
    );

    bindMaterial(MaterialId::Brick);
    drawTexturedQuad(
      B2, C2, C, B,
      {0.0f, 0.0f},
      {b.d * 0.95f, 0.0f},
      {b.d * 0.95f, b.h * 0.08f},
      {0.0f, b.h * 0.08f},
      scaleColor(shade(b.wall, 0.01f), buildingLight)
    );
    drawTexturedQuad(
      C2, D2, D, C,
      {0.0f, 0.0f},
      {b.w * 0.95f, 0.0f},
      {b.w * 0.95f, b.h * 0.08f},
      {0.0f, b.h * 0.08f},
      scaleColor(shade(b.wall, -0.07f), buildingLight * 0.94f)
    );
    unbindMaterial();

    const int floors = b.h > 112.0f ? 3 : (b.h > 86.0f ? 2 : 1);
    const float roofZ = b.h + model::kBuildingModel.roofLift;
    const float parapetH = clampf(
      model::kBuildingModel.parapetBase + floors * model::kBuildingModel.parapetPerFloor,
      model::kBuildingModel.parapetMin,
      model::kBuildingModel.parapetMax
    );
    const float slabDrop = model::kBuildingModel.roofSlabDrop;
    const Vec2 Ar = worldToScreen(b.x, b.y, roofZ);
    const Vec2 Br = worldToScreen(b.x + b.w, b.y, roofZ);
    const Vec2 Cr = worldToScreen(b.x + b.w, b.y + b.d, roofZ);
    const Vec2 Dr = worldToScreen(b.x, b.y + b.d, roofZ);
    const Vec2 A3 = worldToScreen(b.x, b.y, b.h + parapetH);
    const Vec2 B3 = worldToScreen(b.x + b.w, b.y, b.h + parapetH);
    const Vec2 C3 = worldToScreen(b.x + b.w, b.y + b.d, b.h + parapetH);
    const Vec2 D3 = worldToScreen(b.x, b.y + b.d, b.h + parapetH);

    bindMaterial(MaterialId::Roof);
    drawTexturedQuad(
      Ar, Br, Cr, Dr,
      {0.0f, 0.0f},
      {b.w * model::kBuildingModel.roofTexUScale, 0.0f},
      {b.w * model::kBuildingModel.roofTexUScale, b.d * model::kBuildingModel.roofTexVScale},
      {0.0f, b.d * model::kBuildingModel.roofTexVScale},
      scaleColor(shade(b.roof, 0.01f), buildingLight * 0.97f)
    );
    unbindMaterial();

    const Vec2 Br0 = worldToScreen(b.x + b.w, b.y, roofZ - slabDrop);
    const Vec2 Cr0 = worldToScreen(b.x + b.w, b.y + b.d, roofZ - slabDrop);
    const Vec2 Dr0 = worldToScreen(b.x, b.y + b.d, roofZ - slabDrop);
    const Vec2 Ar0 = worldToScreen(b.x, b.y, roofZ - slabDrop);
    drawQuadSolid(Br, Cr, Cr0, Br0, scaleColor(shade(b.roof, -0.26f), buildingLight * 0.85f));
    drawQuadSolid(Cr, Dr, Dr0, Cr0, scaleColor(shade(b.roof, -0.3f), buildingLight * 0.8f));
    drawQuadSolid(Ar, Br, Br0, Ar0, scaleColor(shade(b.roof, -0.22f), buildingLight * 0.88f));
    drawQuadSolid(Ar, Dr, Dr0, Ar0, scaleColor(shade(b.roof, -0.3f), buildingLight * 0.8f));

    const Color parapetMain = scaleColor(shade(b.wall, -0.08f), buildingLight * 0.98f);
    const Color parapetShade = scaleColor(shade(b.wall, -0.16f), buildingLight * 0.9f);
    drawQuadSolid(B2, C2, C3, B3, parapetMain);
    drawQuadSolid(C2, D2, D3, C3, parapetShade);
    drawQuadSolid(A2, D2, D3, A3, parapetShade);
    drawQuadSolid(A2, B2, B3, A3, parapetMain);
    drawLine(B3, C3, shade(b.roof, 0.2f), 1.4f);
    drawLine(C3, D3, shade(b.roof, 0.16f), 1.4f);
    drawLine(A3, B3, shade(b.roof, 0.18f), 1.2f);
    drawLine(A3, D3, shade(b.roof, 0.14f), 1.2f);

    const float corniceZ = b.h - clampf(
      model::kBuildingModel.corniceBase + floors * model::kBuildingModel.cornicePerFloor,
      model::kBuildingModel.corniceMin,
      model::kBuildingModel.corniceMax
    );
    drawWorldRect(
      b.x + b.w - 0.06f, b.y + 0.04f, b.x + b.w + 0.04f, b.y + b.d - 0.04f, corniceZ,
      rgb(172, 139, 112, 0.6f), rgb(172, 139, 112, 0.6f), rgb(133, 106, 88, 0.55f), rgb(133, 106, 88, 0.55f)
    );
    drawWorldRect(
      b.x + 0.04f, b.y + b.d - 0.06f, b.x + b.w - 0.04f, b.y + b.d + 0.04f, corniceZ,
      rgb(172, 139, 112, 0.6f), rgb(172, 139, 112, 0.6f), rgb(133, 106, 88, 0.55f), rgb(133, 106, 88, 0.55f)
    );

    const float bx = b.x + b.w * 0.17f;
    const float by = b.y + b.d * 0.22f;
    const float bw = std::min(0.86f, b.w * 0.2f);
    const float bd = std::min(0.74f, b.d * 0.24f);
    const float bh = floors >= 3 ? 18.0f : 14.0f;
    const Vec2 ba = worldToScreen(bx, by, b.h + bh);
    const Vec2 bb = worldToScreen(bx + bw, by, b.h + bh);
    const Vec2 bc = worldToScreen(bx + bw, by + bd, b.h + bh);
    const Vec2 bdv = worldToScreen(bx, by + bd, b.h + bh);
    const Vec2 ba0 = worldToScreen(bx, by, b.h + 0.6f);
    const Vec2 bb0 = worldToScreen(bx + bw, by, b.h + 0.6f);
    const Vec2 bc0 = worldToScreen(bx + bw, by + bd, b.h + 0.6f);
    const Vec2 bd0 = worldToScreen(bx, by + bd, b.h + 0.6f);
    drawQuadSolid(bb, bc, bc0, bb0, rgb(117, 95, 75));
    drawQuadSolid(bc, bdv, bd0, bc0, rgb(101, 83, 66));
    drawQuadSolid(ba, bb, bc, bdv, rgb(139, 112, 86));
    drawQuadSolid(ba, bb, bb0, ba0, rgb(120, 97, 75));
    drawQuadSolid(ba, bdv, bd0, ba0, rgb(108, 87, 69));

    drawWorldLine3D(b.x + b.w * 0.74f, b.y + b.d * 0.38f, b.h + 0.7f, b.x + b.w * 0.74f, b.y + b.d * 0.38f, b.h + (floors >= 3 ? 20.0f : 16.0f), rgb(121, 76, 64), 1.8f);
    drawWorldLine3D(b.x + b.w * 0.79f, b.y + b.d * 0.41f, b.h + 0.7f, b.x + b.w * 0.79f, b.y + b.d * 0.41f, b.h + (floors >= 3 ? 16.0f : 13.0f), rgb(115, 70, 59), 1.6f);

    for (float z = 16.0f; z < b.h - 8.0f; z += 13.0f) {
      const float a = clampf(0.12f + z * 0.0008f, 0.0f, 0.3f);
      drawWorldLine3D(b.x + b.w, b.y + 0.02f, z, b.x + b.w, b.y + b.d - 0.02f, z, rgb(40, 27, 22, a), 1.0f);
      drawWorldLine3D(b.x + 0.02f, b.y + b.d, z, b.x + b.w - 0.02f, b.y + b.d, z, rgb(40, 27, 22, a), 1.0f);
    }

    for (float y = b.y + 0.55f; y < b.y + b.d - 0.2f; y += 0.68f) {
      drawWorldLine3D(b.x + b.w, y, 8.0f, b.x + b.w, y, b.h - 4.0f, rgb(95, 53, 42, 0.24f), 1.0f);
    }
    for (float x = b.x + 0.52f; x < b.x + b.w - 0.2f; x += 0.69f) {
      drawWorldLine3D(x, b.y + b.d, 8.0f, x, b.y + b.d, b.h - 4.0f, rgb(95, 53, 42, 0.21f), 1.0f);
    }

    const int eastCols = std::max(2, static_cast<int>(std::floor(b.d / 1.3f)));
    const int southCols = std::max(2, static_cast<int>(std::floor(b.w / 1.4f)));
    const bool frontOnSouth = b.front == BuildingFront::South;
    const float southY = b.y + b.d;
    const Color southGlass = frontOnSouth ? b.glass : shade(b.glass, -0.07f);
    const Color southTrim = frontOnSouth ? b.trim : shade(b.trim, -0.11f);

    for (int f = 0; f < floors; f += 1) {
      const float z0 = b.h * 0.22f + static_cast<float>(f) * (b.h * 0.19f);
      const float z1 = z0 + 14.0f;

      for (int c = 0; c < eastCols; c += 1) {
        const float y0 = b.y + 0.33f + c * ((b.d - 0.74f) / eastCols);
        drawWindowX(b.x + b.w, y0, y0 + 0.54f, z0, z1, b.glass, b.trim, -1.0f);
      }

      for (int c = 0; c < southCols; c += 1) {
        const float x0 = b.x + 0.34f + c * ((b.w - 0.75f) / southCols);
        drawWindowY(southY, x0, x0 + 0.58f, z0, z1, southGlass, southTrim, -1.0f);
      }
    }

    if (frontOnSouth) {
      drawWindowY(southY, b.x + b.w * 0.43f, b.x + b.w * 0.57f, 2.0f, 24.0f, shade(b.trim, -0.08f), b.trim, -1.0f);
    } else {
      drawWindowY(southY, b.x + b.w * 0.44f, b.x + b.w * 0.56f, 3.5f, 18.5f, shade(b.trim, -0.2f), shade(b.trim, -0.16f), -1.0f);
    }

    if (b.h > 112.0f) {
      const float fx = b.x + b.w + 0.02f;
      const float yL = b.y + b.d * 0.28f;
      const float yR = b.y + b.d * 0.72f;
      for (int f = 0; f < floors; f += 1) {
        const float z = 28.0f + static_cast<float>(f) * 26.0f;
        drawWorldLine3D(fx, yL, z, fx, yR, z, rgb(72, 73, 78, 0.9f), 1.6f);
        drawWorldLine3D(fx, yL, z - 10.0f, fx, yL, z, rgb(72, 73, 78, 0.86f), 1.4f);
        drawWorldLine3D(fx, yR, z - 10.0f, fx, yR, z, rgb(72, 73, 78, 0.86f), 1.4f);
      }
      drawWorldLine3D(fx, (yL + yR) * 0.5f, 16.0f, fx, (yL + yR) * 0.5f, b.h - 6.0f, rgb(65, 68, 72, 0.75f), 1.2f);
    } else {
      if (frontOnSouth) {
        const Vec2 porchA = worldToScreen(b.x + b.w * 0.19f, southY + 0.05f, 26.0f);
        const Vec2 porchB = worldToScreen(b.x + b.w * 0.81f, southY + 0.05f, 26.0f);
        const Vec2 porchC = worldToScreen(b.x + b.w * 0.81f, southY + 0.34f, 20.0f);
        const Vec2 porchD = worldToScreen(b.x + b.w * 0.19f, southY + 0.34f, 20.0f);
        drawQuad(porchA, porchB, porchC, porchD, rgb(118, 74, 63), rgb(114, 72, 61), rgb(96, 60, 50), rgb(102, 64, 54));

        const Vec2 shopL0 = worldToScreen(b.x + b.w * 0.14f, southY, 6.0f);
        const Vec2 shopL1 = worldToScreen(b.x + b.w * 0.36f, southY, 6.0f);
        const Vec2 shopL2 = worldToScreen(b.x + b.w * 0.36f, southY, 24.0f);
        const Vec2 shopL3 = worldToScreen(b.x + b.w * 0.14f, southY, 24.0f);
        drawQuadSolid(shopL0, shopL1, shopL2, shopL3, rgb(176, 203, 226, 0.92f));

        const Vec2 shopR0 = worldToScreen(b.x + b.w * 0.64f, southY, 6.0f);
        const Vec2 shopR1 = worldToScreen(b.x + b.w * 0.86f, southY, 6.0f);
        const Vec2 shopR2 = worldToScreen(b.x + b.w * 0.86f, southY, 24.0f);
        const Vec2 shopR3 = worldToScreen(b.x + b.w * 0.64f, southY, 24.0f);
        drawQuadSolid(shopR0, shopR1, shopR2, shopR3, rgb(176, 203, 226, 0.92f));
      } else {
        drawWindowY(southY, b.x + b.w * 0.22f, b.x + b.w * 0.36f, 5.0f, 18.0f, shade(b.trim, -0.17f), shade(b.trim, -0.2f), -1.0f);
        drawWindowY(southY, b.x + b.w * 0.64f, b.x + b.w * 0.78f, 5.0f, 18.0f, shade(b.trim, -0.17f), shade(b.trim, -0.2f), -1.0f);
        drawWorldLine3D(b.x + b.w * 0.42f, southY + 0.03f, 0.0f, b.x + b.w * 0.42f, southY + 0.03f, 20.0f, rgb(84, 86, 90, 0.78f), 1.3f);
        drawWorldLine3D(b.x + b.w * 0.58f, southY + 0.03f, 0.0f, b.x + b.w * 0.58f, southY + 0.03f, 20.0f, rgb(84, 86, 90, 0.78f), 1.3f);
      }
    }
    if (frontOnSouth) {
      const Vec2 stoopA = worldToScreen(b.x + b.w * 0.39f, southY + 0.08f, 0.0f);
      const Vec2 stoopB = worldToScreen(b.x + b.w * 0.61f, southY + 0.08f, 0.0f);
      const Vec2 stoopC = worldToScreen(b.x + b.w * 0.61f, southY + 0.52f, 0.0f);
      const Vec2 stoopD = worldToScreen(b.x + b.w * 0.39f, southY + 0.52f, 0.0f);
      drawQuadSolid(stoopA, stoopB, stoopC, stoopD, rgb(166, 171, 173));
      drawLine(stoopA, stoopB, rgb(116, 120, 123), 1.2f);

      const Vec2 awA = worldToScreen(b.x + b.w * 0.31f, southY + 0.03f, 30.0f);
      const Vec2 awB = worldToScreen(b.x + b.w * 0.69f, southY + 0.03f, 30.0f);
      const Vec2 awC = worldToScreen(b.x + b.w * 0.69f, southY + 0.36f, 22.0f);
      const Vec2 awD = worldToScreen(b.x + b.w * 0.31f, southY + 0.36f, 22.0f);
      drawQuad(awA, awB, awC, awD, rgb(118, 74, 63), rgb(111, 70, 59), rgb(95, 58, 49), rgb(103, 63, 54));
      drawLine(awA, awB, rgb(152, 111, 96, 0.75f), 1.0f);
      drawLine(awC, awD, rgb(54, 31, 28, 0.7f), 1.0f);

      drawWorldLine3D(b.x + b.w * 0.36f, southY + 0.13f, 0.0f, b.x + b.w * 0.36f, southY + 0.13f, 23.0f, rgb(86, 82, 79), 1.4f);
      drawWorldLine3D(b.x + b.w * 0.64f, southY + 0.13f, 0.0f, b.x + b.w * 0.64f, southY + 0.13f, 23.0f, rgb(86, 82, 79), 1.4f);
    } else {
      drawWorldRect(
        b.x + b.w * 0.28f, southY + 0.03f, b.x + b.w * 0.72f, southY + 0.16f, 0.04f,
        rgb(118, 122, 126, 0.5f), rgb(118, 122, 126, 0.5f), rgb(88, 92, 97, 0.45f), rgb(88, 92, 97, 0.45f)
      );
    }

    const float cX = b.x + b.w * 0.19f;
    const float cY = b.y + b.d * 0.24f;
    const float cW = 0.42f;
    const float cD = 0.36f;
    const float cH = 18.0f;

    const Vec2 ca = worldToScreen(cX, cY, b.h + cH);
    const Vec2 cb = worldToScreen(cX + cW, cY, b.h + cH);
    const Vec2 cc = worldToScreen(cX + cW, cY + cD, b.h + cH);
    const Vec2 cd = worldToScreen(cX, cY + cD, b.h + cH);

    const Vec2 ca0 = worldToScreen(cX, cY, b.h);
    const Vec2 cb0 = worldToScreen(cX + cW, cY, b.h);
    const Vec2 cc0 = worldToScreen(cX + cW, cY + cD, b.h);
    const Vec2 cd0 = worldToScreen(cX, cY + cD, b.h);

    drawQuadSolid(cb, cc, cc0, cb0, rgb(112, 67, 54));
    drawQuadSolid(cc, cd, cd0, cc0, rgb(94, 57, 46));
    drawQuadSolid(ca, cb, cc, cd, rgb(141, 89, 70));
    drawQuadSolid(ca, cb, cb0, ca0, rgb(118, 74, 59));
    drawQuadSolid(ca, cd, cd0, ca0, rgb(105, 66, 53));
  }

  void drawTree(const Tree &tree) const {
    const Vec2 base = worldToScreen(tree.x, tree.y);
    const float size = tree.size;
    const float sway = std::sin(worldTime * model::kTreeModel.windSpeed + tree.x * 0.2f + tree.y * 0.16f) * model::kTreeModel.windAmp;
    const float trunkLean = std::sin(tree.x * 0.21f + tree.y * 0.19f) * model::kTreeModel.trunkLeanAmp;

    drawEllipse(base.x, base.y + 10.0f, tileW * 0.14f * size, tileH * 0.3f * size, rgb(7, 16, 11, 0.26f), 24);

    const float trunkH = model::kTreeModel.trunkHeight * size;
    const float tw = model::kTreeModel.trunkHalfWidth;
    const float td = model::kTreeModel.trunkDepth;
    const Vec2 tA0 = worldToScreen(tree.x - tw, tree.y - td, 0.0f);
    const Vec2 tB0 = worldToScreen(tree.x + tw, tree.y - td, 0.0f);
    const Vec2 tC0 = worldToScreen(tree.x + tw * 0.58f, tree.y + td, 0.0f);
    const Vec2 tD0 = worldToScreen(tree.x - tw * 0.58f, tree.y + td, 0.0f);
    const Vec2 tA1 = worldToScreen(tree.x - tw * 0.66f + trunkLean, tree.y - td * 0.82f, trunkH);
    const Vec2 tB1 = worldToScreen(tree.x + tw * 0.66f + trunkLean, tree.y - td * 0.82f, trunkH);
    const Vec2 tC1 = worldToScreen(tree.x + tw * 0.42f + trunkLean, tree.y + td * 0.74f, trunkH);
    const Vec2 tD1 = worldToScreen(tree.x - tw * 0.42f + trunkLean, tree.y + td * 0.74f, trunkH);
    drawQuadSolid(tD1, tC1, tC0, tD0, rgb(95, 61, 40));
    drawQuadSolid(tA1, tB1, tB0, tA0, rgb(111, 73, 48));
    drawQuadSolid(tB1, tC1, tC0, tB0, rgb(85, 55, 37));
    drawLine(tA1, tB1, rgb(139, 97, 67, 0.42f), 1.0f);

    const Vec2 branchRoot = worldToScreen(tree.x + trunkLean * 0.5f, tree.y - 0.01f, trunkH * 0.7f);
    drawLine(branchRoot, worldToScreen(tree.x - 0.23f + trunkLean, tree.y - 0.11f, trunkH * 0.9f), rgb(80, 52, 35, 0.86f), 1.6f);
    drawLine(branchRoot, worldToScreen(tree.x + 0.25f + trunkLean, tree.y + 0.07f, trunkH * 0.88f), rgb(80, 52, 35, 0.86f), 1.6f);

    for (const model::TreeClusterPoint &cluster : model::kTreeCanopy) {
      const Vec2 p = worldToScreen(
        tree.x + cluster.x * size + trunkLean * 0.35f,
        tree.y + cluster.y * size,
        cluster.z * size
      );
      const Color leaf = cluster.shade > 0.0f ? rgb(63, 132, 74) : rgb(52, 115, 64);
      drawEllipse(
        p.x + sway * 0.16f,
        p.y,
        cluster.rx * size,
        cluster.ry * size,
        shade(leaf, cluster.shade),
        24
      );
    }

    const Vec2 highlight = worldToScreen(tree.x + trunkLean * 0.2f, tree.y - 0.05f, 43.0f * size);
    drawEllipse(highlight.x + sway * 0.18f, highlight.y - 1.0f, 6.8f * size, 4.6f * size, rgb(176, 226, 153, model::kTreeModel.canopyHighlightAlpha), 18);
  }

  void drawShrub(const Shrub &shrub) const {
    const Vec2 p = worldToScreen(shrub.x, shrub.y);
    const float wobble = std::sin(worldTime * 0.92f + shrub.x * 0.6f + shrub.y * 0.37f) * 1.1f;
    const float s = shrub.size;

    drawEllipse(p.x, p.y + 5.0f, tileW * 0.1f * s, tileH * 0.2f * s, rgb(7, 17, 11, 0.23f), 18);
    drawEllipse(p.x - 4.0f + wobble * 0.12f, p.y - 4.0f, 6.8f * s, 5.3f * s, rgb(60, 120, 64), 18);
    drawEllipse(p.x + 4.2f + wobble * 0.09f, p.y - 3.6f, 6.3f * s, 5.0f * s, rgb(64, 128, 67), 18);
    drawEllipse(p.x + wobble * 0.1f, p.y - 7.2f, 7.4f * s, 5.8f * s, rgb(73, 139, 73), 18);
    drawEllipse(p.x - 2.0f, p.y - 8.2f, 3.5f * s, 2.4f * s, rgb(169, 222, 143, 0.25f), 14);
  }

  void drawStreetLight(const StreetLight &light) const {
    drawWorldLine3D(light.x, light.y, 0.0f, light.x, light.y, 45.0f, rgb(79, 90, 95), 3.0f);
    drawWorldLine3D(light.x, light.y, 45.0f, light.x + 0.22f, light.y + 0.09f, 45.0f, rgb(79, 90, 95), 2.0f);

    const Vec2 lamp = worldToScreen(light.x + 0.22f, light.y + 0.09f, 45.0f);
    drawEllipse(lamp.x, lamp.y + 1.5f, 2.9f, 2.2f, rgb(144, 149, 152), 14);
    drawEllipse(lamp.x, lamp.y + 5.0f, 7.5f, 3.8f, rgb(46, 52, 58, 0.24f), 18);
  }

  void drawPoop(const Poop &poop) const {
    const Vec2 p = worldToScreen(poop.pos.x, poop.pos.y);
    const float bob = std::sin(worldTime * 1.2f + poop.phase) * 0.75f;

    drawEllipse(p.x, p.y + 6.0f, tileW * 0.13f, tileH * 0.22f, rgb(15, 12, 10, 0.27f), 18);
    drawEllipse(p.x, p.y - 2.0f + bob, 6.2f, 5.5f, rgb(90, 60, 37), 16);
    drawEllipse(p.x - 3.0f, p.y + 3.0f + bob, 4.3f, 3.7f, rgb(90, 60, 37), 14);
    drawEllipse(p.x + 3.2f, p.y + 3.0f + bob, 4.1f, 3.5f, rgb(90, 60, 37), 14);
  }

  void drawPuddle(const VomitPuddle &puddle) const {
    const Vec2 p = worldToScreen(puddle.pos.x, puddle.pos.y);
    const float freshness = clampf(puddle.ttl / 24.0f, 0.0f, 1.0f);
    const float wobble = std::sin(worldTime * 2.1f + puddle.pos.x * 0.8f + puddle.pos.y * 0.37f) * 0.9f;

    drawEllipse(p.x + 0.6f, p.y + 4.6f, tileW * 0.2f, tileH * 0.26f, rgb(19, 33, 16, 0.42f), 24);
    drawEllipse(p.x - 3.4f, p.y + 5.4f, tileW * 0.11f, tileH * 0.16f, rgb(16, 28, 13, 0.3f), 20);
    drawEllipse(p.x + 4.1f, p.y + 5.1f, tileW * 0.1f, tileH * 0.15f, rgb(16, 28, 13, 0.3f), 20);

    const Color slime = rgb(137, 188, 74, 0.72f + freshness * 0.2f);
    const Color bile = rgb(162, 204, 91, 0.58f + freshness * 0.18f);
    const Color darkBile = rgb(93, 132, 53, 0.68f);
    drawEllipse(p.x + wobble * 0.12f, p.y + 1.6f, tileW * 0.15f, tileH * 0.19f, slime, 24);
    drawEllipse(p.x - 3.3f + wobble * 0.08f, p.y + 1.8f, tileW * 0.09f, tileH * 0.12f, bile, 18);
    drawEllipse(p.x + 3.9f - wobble * 0.1f, p.y + 2.4f, tileW * 0.085f, tileH * 0.115f, bile, 18);
    drawEllipse(p.x + 0.8f, p.y + 0.3f, tileW * 0.07f, tileH * 0.095f, darkBile, 16);

    const float streakDir = std::sin(puddle.pos.x * 1.1f + puddle.pos.y * 0.9f);
    const Vec2 s0 = {p.x + 1.2f, p.y + 2.1f};
    const Vec2 s1 = {p.x + 7.0f + streakDir * 2.0f, p.y + 4.6f};
    const Vec2 s2 = {p.x - 5.8f - streakDir * 1.3f, p.y + 5.1f};
    drawLine(s0, s1, rgb(143, 191, 83, 0.58f), 1.8f);
    drawLine(s0, s2, rgb(132, 179, 72, 0.54f), 1.6f);
    drawEllipse(s1.x, s1.y + 0.2f, 1.3f, 0.95f, rgb(145, 195, 85, 0.7f), 12);
    drawEllipse(s2.x, s2.y + 0.2f, 1.25f, 0.92f, rgb(135, 184, 76, 0.7f), 12);
  }

  void drawDog(const Dog &dog, bool isFreya) const {
    const Vec2 p = worldToScreen(dog.pos.x, dog.pos.y);
    const float bob = std::sin(dog.step) * 1.05f;
    const float wag = std::sin(dog.step * 0.82f) * 2.35f;
    const float breath = std::sin(worldTime * 2.3f + dog.pos.x * 0.4f + dog.pos.y * 0.33f) * 0.45f;
    const float light = localLightAt(dog.pos.x, dog.pos.y, isFreya ? 1.07f : 1.0f);
    const int dirBucket = quantizeDirection8(dog.screenFacing);
    const float dirAngle = directionAngle8(dirBucket);
    const Vec2 forward{std::cos(dirAngle), std::sin(dirAngle)};
    const Vec2 right = dirToRight(forward);
    const float bodyScale = isFreya ? 1.15f : dog.bodyScale;
    const float legScale = isFreya ? 1.08f : dog.legScale;
    const float earDrop = isFreya ? 0.96f : dog.earDrop;
    const float snoutScale = isFreya ? 1.14f : dog.snoutScale;
    const float furFluff = isFreya ? 1.03f : dog.furFluff;

    auto toScreen = [&](float f, float r, float down = 0.0f) {
      return Vec2{
        p.x + forward.x * f + right.x * r,
        p.y - 9.4f + bob + forward.y * f + right.y * r + down
      };
    };

    drawEllipse(p.x + forward.x * 1.25f, p.y + 8.1f + forward.y * 0.95f, tileW * 0.19f, tileH * 0.25f, rgb(8, 18, 12, 0.29f), 24);

    const Color body = isFreya ? rgb(17, 17, 17) : dog.color;
    const Color bodyLit = scaleColor(body, light * 1.02f);
    const Color bodyDark = scaleColor(shade(body, -0.17f), light * 0.98f);
    const Color bodyHighlight = scaleColor(shade(body, 0.13f), light * 1.04f);
    const Vec2 rump = toScreen(-5.4f * bodyScale, 0.0f);
    const Vec2 torso = toScreen(-1.4f * bodyScale, 0.0f);
    const Vec2 chest = toScreen(3.2f * bodyScale, 0.0f);
    const Vec2 neck = toScreen(6.9f * bodyScale, 0.0f);
    const Vec2 head = toScreen(10.2f * bodyScale, 0.0f);
    const Vec2 muzzle = toScreen((13.0f + (snoutScale - 1.0f) * 2.1f) * bodyScale, 0.03f);

    drawEllipse(rump.x, rump.y, 6.45f * bodyScale, 4.8f * bodyScale, bodyDark, 26);
    drawEllipse(torso.x, torso.y, 8.4f * bodyScale, 5.95f * bodyScale + breath * 0.2f, bodyLit, 28);
    drawEllipse(chest.x, chest.y, 7.35f * bodyScale, 5.5f * bodyScale, bodyHighlight, 24);
    drawEllipse(neck.x, neck.y - 0.5f, 4.75f * bodyScale, 3.85f * bodyScale, bodyHighlight, 22);
    drawEllipse(head.x, head.y - 0.62f, (isFreya ? 5.45f : 5.1f) * bodyScale, (isFreya ? 4.35f : 4.2f) * bodyScale, bodyDark, 24);
    drawEllipse(muzzle.x, muzzle.y + 0.2f, (isFreya ? 3.95f : 3.3f) * snoutScale, (isFreya ? 2.7f : 2.35f), scaleColor(shade(body, -0.22f), light), 22);
    drawEllipse(
      head.x - forward.x * 1.0f + right.x * 0.3f,
      head.y - forward.y * 1.0f + right.y * 0.3f - 1.5f,
      2.0f,
      1.5f,
      scaleColor(rgb(255, 255, 255, isFreya ? 0.34f : 0.26f), light),
      12
    );

    if (!isFreya) {
      for (int i = 0; i < 5; i += 1) {
        const float t = static_cast<float>(i) / 4.0f;
        const Vec2 coat = toScreen(-4.2f + t * 9.1f, -3.0f + std::sin(t * PI * 2.0f + dog.pos.x * 0.9f) * 1.5f);
        drawEllipse(coat.x, coat.y, 1.05f * furFluff, 0.8f * furFluff, scaleColor(shade(body, -0.1f), light), 12);
      }
    }

    const float earSwing = std::sin(dog.step * 1.18f + static_cast<float>(dirBucket) * 0.45f) * 0.65f;
    if (isFreya) {
      const Color earColor = scaleColor(shade(body, -0.2f), light);
      const Vec2 earL = toScreen(8.9f, -3.3f + earSwing * 0.21f, 2.0f);
      const Vec2 earR = toScreen(8.9f, 3.3f - earSwing * 0.21f, 2.0f);
      drawEllipse(earL.x, earL.y, 2.05f, 3.45f, earColor, 16);
      drawEllipse(earR.x, earR.y, 2.05f, 3.45f, earColor, 16);
      drawEllipse(earL.x + 0.22f, earL.y + 0.64f, 1.15f, 1.5f, scaleColor(shade(body, -0.3f), light), 12);
      drawEllipse(earR.x + 0.2f, earR.y + 0.64f, 1.15f, 1.5f, scaleColor(shade(body, -0.3f), light), 12);

      const Color coatShadow = scaleColor(shade(body, -0.2f), light);
      for (int i = 0; i < 5; i += 1) {
        const float t = static_cast<float>(i) / 4.0f;
        const Vec2 coat = toScreen(-3.2f + t * 10.0f, std::sin(t * PI * 2.0f + 0.6f) * 3.3f);
        drawEllipse(coat.x, coat.y, 1.2f, 0.86f, coatShadow, 12);
      }
      drawEllipse(chest.x + forward.x * 0.35f, chest.y + forward.y * 0.35f + 1.15f, 4.7f, 2.75f, scaleColor(shade(body, -0.26f), light), 14);
    } else {
      const float droop = 1.4f + earDrop * 2.4f;
      const Vec2 earL = toScreen(9.6f, -3.1f + earSwing * 0.35f, droop);
      const Vec2 earR = toScreen(9.6f, 3.1f - earSwing * 0.35f, droop);
      drawEllipse(earL.x, earL.y, 1.65f, 2.55f + earDrop * 1.2f, scaleColor(shade(body, -0.23f), light), 14);
      drawEllipse(earR.x, earR.y, 1.65f, 2.55f + earDrop * 1.2f, scaleColor(shade(body, -0.2f), light * 0.97f), 14);
    }

    struct LegInfo {
      Vec2 root;
      Vec2 knee;
      Vec2 foot;
      float depth = 0.0f;
    };
    std::vector<LegInfo> legs;
    const std::array<Vec2, 4> legRoots = {{{-4.3f, -2.4f}, {-3.8f, 2.4f}, {3.8f, -2.3f}, {4.2f, 2.3f}}};
    const std::array<float, 4> legPhases = {{0.0f, PI, PI, 0.0f}};
    for (int i = 0; i < 4; i += 1) {
      if (isFreya && i == 1) {
        continue;
      }
      const float stride = std::sin(dog.step * 1.15f + legPhases[static_cast<size_t>(i)]) * 1.25f;
      const float lift = std::max(0.0f, std::cos(dog.step * 1.15f + legPhases[static_cast<size_t>(i)])) * 1.1f;
      const Vec2 root = toScreen(legRoots[static_cast<size_t>(i)].x * bodyScale, legRoots[static_cast<size_t>(i)].y * bodyScale, 1.0f);
      const Vec2 knee = toScreen(
        legRoots[static_cast<size_t>(i)].x * bodyScale + 0.45f + stride * 0.45f,
        legRoots[static_cast<size_t>(i)].y * bodyScale + stride * 0.07f,
        (4.9f - lift * 0.6f) * legScale
      );
      const Vec2 foot = toScreen(
        legRoots[static_cast<size_t>(i)].x * bodyScale + 0.8f + stride,
        legRoots[static_cast<size_t>(i)].y * bodyScale + stride * 0.18f,
        (9.2f - lift) * legScale
      );
      legs.push_back({root, knee, foot, foot.y});
    }
    std::sort(legs.begin(), legs.end(), [](const LegInfo &a, const LegInfo &b) {
      return a.depth < b.depth;
    });
    for (const LegInfo &leg : legs) {
      const Color legColor = isFreya ? scaleColor(rgb(8, 8, 8), light) : scaleColor(shade(body, -0.26f), light);
      drawLine(leg.root, leg.knee, legColor, 2.1f);
      drawLine(leg.knee, leg.foot, legColor, 2.0f);
      drawEllipse(leg.foot.x, leg.foot.y + 0.7f, 1.3f, 0.95f, scaleColor(shade(body, -0.32f), light), 10);
    }

    const Vec2 tailBase = toScreen(-8.6f, 0.0f);
    const Vec2 tailMid = addVec(tailBase, addVec(scaleVec(forward, -2.5f), scaleVec(right, wag * 0.2f)));
    const Vec2 tailTip = addVec(tailBase, addVec(scaleVec(forward, -5.0f), scaleVec(right, wag * 0.37f)));
    drawLine(tailBase, tailMid, scaleColor(shade(body, -0.34f), light), isFreya ? 2.5f : 2.2f);
    drawLine(tailMid, tailTip, scaleColor(shade(body, -0.32f), light), isFreya ? 2.2f : 1.9f);
    drawEllipse(tailTip.x, tailTip.y, 1.2f * furFluff, 0.9f * furFluff, scaleColor(shade(body, -0.3f), light), 10);

    const Vec2 eyeL = toScreen(12.2f, -1.25f, -0.8f);
    const Vec2 eyeR = toScreen(12.2f, 1.25f, -0.8f);
    drawEllipse(eyeL.x, eyeL.y, 0.58f, 0.55f, scaleColor(rgb(16, 16, 16), light), 8);
    drawEllipse(eyeR.x, eyeR.y, 0.58f, 0.55f, scaleColor(rgb(16, 16, 16), light), 8);
    drawEllipse(muzzle.x + 0.8f, muzzle.y + 0.2f, 0.82f, 0.68f, scaleColor(rgb(12, 12, 12), light), 10);
    drawLine({muzzle.x - 0.3f, muzzle.y + 0.9f}, {muzzle.x + 1.1f, muzzle.y + 0.9f}, scaleColor(rgb(24, 24, 24, 0.45f), light), 0.9f);

    if (isFreya) {
      drawEllipse(torso.x - 1.2f, torso.y + 1.6f, 4.9f, 2.65f, rgb(34, 34, 34, 0.54f), 16);
      const Vec2 collarL = toScreen(6.7f, -3.05f, 0.85f);
      const Vec2 collarR = toScreen(6.7f, 3.05f, 0.85f);
      drawLine(collarL, collarR, scaleColor(rgb(179, 78, 66, 0.95f), light), 2.2f);
      drawEllipse(muzzle.x + 0.45f, muzzle.y + 1.0f, 2.0f, 1.0f, scaleColor(rgb(19, 19, 19, 0.5f), light), 12);
      drawEllipse(muzzle.x + 1.05f, muzzle.y + 1.08f, 0.34f, 0.24f, scaleColor(rgb(225, 130, 124, 0.72f), light), 10);

      if (freya.vomitingTimer > 0.0f) {
        const float pulse = 2.2f + std::sin(worldTime * 18.0f) * 1.0f;
        const Vec2 splash = toScreen(16.3f, 0.0f, 0.6f);
        drawEllipse(splash.x, splash.y, pulse, pulse * 0.7f, rgb(145, 195, 92, 0.84f), 14);
      }
    }
  }

  void drawBarkPulses() const {
    for (const BarkPulse &pulse : barkPulses) {
      const float t = clampf(pulse.age / pulse.ttl, 0.0f, 1.0f);
      const float r = lerpf(pulse.r0, pulse.r1, t);
      const float alpha = (1.0f - t) * pulse.color.a;
      const Vec2 p = worldToScreen(pulse.pos.x, pulse.pos.y);
      drawEllipseOutline(p.x, p.y - 23.0f, r, r * 0.65f, {pulse.color.r, pulse.color.g, pulse.color.b, alpha}, 2.0f, 24);
      drawEllipseOutline(p.x, p.y - 23.0f, r * 0.62f, r * 0.43f, {pulse.color.r, pulse.color.g, pulse.color.b, alpha * 0.7f}, 1.6f, 24);
    }
  }

  void drawLabels() const {
    for (const FloatLabel &label : labels) {
      const float t = clampf(label.age / label.ttl, 0.0f, 1.0f);
      const float alpha = 1.0f - t;
      const float lift = t * 22.0f;
      const Vec2 p = worldToScreen(label.pos.x, label.pos.y);
      const float scale = 2.0f;
      const float textWidth = label.text.size() * 6.0f * scale;
      const float x = p.x - textWidth * 0.5f;
      const float y = p.y - 38.0f - lift;

      drawRect(x - 6.0f, y - 4.0f, textWidth + 12.0f, 20.0f, rgb(8, 8, 8, 0.5f * alpha));
      drawText(label.text, x, y, scale, {label.color.r, label.color.g, label.color.b, alpha});
    }
  }

  void drawBar(float x, float y, float w, float h, float value, const Color &fill, const Color &bg) const {
    drawRect(x, y, w, h, bg);
    drawRectBorder(x, y, w, h, rgb(225, 241, 236, 0.38f));
    const float clamped = clampf(value, 0.0f, 100.0f);
    drawRect(x + 1.0f, y + 1.0f, (w - 2.0f) * (clamped / 100.0f), h - 2.0f, fill);
  }

  void drawHUD() {
    const float panelX = 16.0f;
    const float panelY = 16.0f;
    const float panelW = std::min(440.0f, windowW * 0.58f);
    const float panelH = 154.0f;

    drawRect(panelX, panelY, panelW, panelH, rgb(8, 16, 20, 0.66f));
    drawRectBorder(panelX, panelY, panelW, panelH, rgb(206, 235, 223, 0.56f), 1.2f);

    drawText("FREYA", panelX + 14.0f, panelY + 10.0f, 2.5f, rgb(237, 255, 248));

    const float barX = panelX + 58.0f;
    const float barW = panelW - 70.0f;

    drawEllipse(panelX + 27.0f, panelY + 47.0f, 10.0f, 8.0f, rgb(255, 125, 82), 18);
    drawBar(barX, panelY + 38.0f, barW, 18.0f, freya.hunger, rgb(255, 117, 79), rgb(19, 29, 33, 0.86f));
    drawText("HUNGER", barX + 8.0f, panelY + 42.0f, 1.8f, rgb(241, 248, 244));
    drawText(std::to_string(static_cast<int>(std::round(freya.hunger))) + "%", barX + barW - 42.0f, panelY + 42.0f, 1.8f, rgb(241, 248, 244));

    drawEllipse(panelX + 27.0f, panelY + 75.0f, 10.0f, 8.0f, rgb(178, 218, 102), 18);
    drawBar(barX, panelY + 66.0f, barW, 18.0f, freya.vomit, rgb(178, 218, 102), rgb(19, 29, 33, 0.86f));
    drawText("VOMIT", barX + 8.0f, panelY + 70.0f, 1.8f, rgb(241, 248, 244));
    drawText(std::to_string(static_cast<int>(std::round(freya.vomit))) + "%", barX + barW - 42.0f, panelY + 70.0f, 1.8f, rgb(241, 248, 244));

    drawEllipse(panelX + 27.0f, panelY + 103.0f, 10.0f, 8.0f, rgb(105, 182, 236), 18);
    drawBar(barX, panelY + 94.0f, barW, 18.0f, freya.social, rgb(105, 182, 236), rgb(19, 29, 33, 0.86f));
    drawText("SOCIAL", barX + 8.0f, panelY + 98.0f, 1.8f, rgb(241, 248, 244));
    drawText(std::to_string(static_cast<int>(std::round(freya.social))) + "%", barX + barW - 42.0f, panelY + 98.0f, 1.8f, rgb(241, 248, 244));

    const bool vomitReady = freya.vomit >= 100.0f;
    if (vomitReady) {
      hudVomitReadyFlash += 0.08f;
      const float flash = 0.5f + std::sin(hudVomitReadyFlash) * 0.5f;
      drawRect(panelX + 12.0f, panelY + 122.0f, panelW - 24.0f, 24.0f, rgb(151, 205, 83, 0.2f + flash * 0.16f));
      drawText("SPACE TO VOMIT", panelX + 20.0f, panelY + 128.0f, 2.0f, rgb(220, 246, 182));
    } else {
      drawText("E TO EAT POOP", panelX + 20.0f, panelY + 128.0f, 2.0f, rgb(241, 227, 191));
    }

    if (hudNoPoopTimer > 0.0f) {
      const float a = clampf(hudNoPoopTimer / 0.9f, 0.0f, 1.0f);
      drawText("NO POOP IN RANGE", panelX + panelW + 18.0f, panelY + 18.0f, 2.0f, rgb(205, 232, 240, a));
    }

    if (hudEatTimer > 0.0f) {
      const float a = clampf(hudEatTimer / 0.8f, 0.0f, 1.0f);
      drawText("POOP EATEN", panelX + panelW + 18.0f, panelY + 42.0f, 2.0f, rgb(233, 205, 160, a));
    }

    const float objectiveY = panelY + panelH + 8.0f;
    const float objectiveH = 44.0f;
    drawRect(panelX, objectiveY, panelW, objectiveH, rgb(8, 16, 20, 0.66f));
    drawRectBorder(panelX, objectiveY, panelW, objectiveH, rgb(206, 235, 223, 0.56f), 1.2f);
    drawText("OBJECTIVE", panelX + 14.0f, objectiveY + 8.0f, 1.7f, rgb(219, 244, 231));
    if (objectivePukeOnDogComplete) {
      drawText("PUKE ON A DOG: COMPLETE", panelX + 14.0f, objectiveY + 24.0f, 1.75f, rgb(206, 244, 152));
    } else {
      drawText("PUKE ON A DOG: IN PROGRESS", panelX + 14.0f, objectiveY + 24.0f, 1.75f, rgb(244, 229, 182));
    }
  }

  void drawMiniMap() const {
    const float mapW = std::min(250.0f, windowW * 0.28f);
    const float mapH = std::min(190.0f, windowH * 0.28f);
    const float mapX = windowW - mapW - 18.0f;
    const float mapY = 18.0f;

    drawRect(mapX, mapY, mapW, mapH, rgb(9, 18, 24, 0.8f));
    drawRectBorder(mapX, mapY, mapW, mapH, rgb(199, 227, 228, 0.74f));

    const float sx = mapW / MAP_W;
    const float sy = mapH / MAP_H;

    drawRect(mapX, mapY, mapW, mapH, rgb(92, 134, 84));

    for (const RectArea &sw : sidewalkAreas) {
      drawRect(mapX + sw.x0 * sx, mapY + sw.y0 * sy, (sw.x1 - sw.x0) * sx, (sw.y1 - sw.y0) * sy, rgb(176, 184, 186));
    }
    for (const RectArea &sw : alleyShoulderAreas) {
      drawRect(mapX + sw.x0 * sx, mapY + sw.y0 * sy, (sw.x1 - sw.x0) * sx, (sw.y1 - sw.y0) * sy, rgb(157, 166, 170));
    }

    for (const RectArea &road : roadAreas) {
      drawRect(mapX + road.x0 * sx, mapY + road.y0 * sy, (road.x1 - road.x0) * sx, (road.y1 - road.y0) * sy, rgb(85, 91, 98));
    }
    for (const RectArea &alley : alleyAreas) {
      drawRect(mapX + alley.x0 * sx, mapY + alley.y0 * sy, (alley.x1 - alley.x0) * sx, (alley.y1 - alley.y0) * sy, rgb(104, 110, 117));
    }

    for (const Building &b : buildings) {
      drawRect(mapX + b.x * sx, mapY + b.y * sy, b.w * sx, b.d * sy, rgb(81, 58, 42));
    }

    for (const Poop &poop : poops) {
      drawRect(mapX + poop.pos.x * sx - 1.0f, mapY + poop.pos.y * sy - 1.0f, 2.0f, 2.0f, rgb(145, 95, 57));
    }

    for (const VomitPuddle &puddle : puddles) {
      drawRect(mapX + puddle.pos.x * sx - 1.0f, mapY + puddle.pos.y * sy - 1.0f, 2.0f, 2.0f, rgb(135, 183, 85));
    }

    for (const Dog &dog : dogs) {
      drawEllipse(mapX + dog.pos.x * sx, mapY + dog.pos.y * sy, 2.4f, 2.4f, rgb(245, 236, 223), 10);
    }

    drawEllipse(mapX + freya.pos.x * sx, mapY + freya.pos.y * sy, 3.0f, 3.0f, rgb(8, 8, 8), 12);
    drawRect(mapX + dogParkArea.x0 * sx, mapY + dogParkArea.y0 * sy, (dogParkArea.x1 - dogParkArea.x0) * sx, (dogParkArea.y1 - dogParkArea.y0) * sy, rgb(96, 170, 96, 0.38f));
    drawRectBorder(mapX + dogParkArea.x0 * sx, mapY + dogParkArea.y0 * sy, (dogParkArea.x1 - dogParkArea.x0) * sx, (dogParkArea.y1 - dogParkArea.y0) * sy, rgb(196, 235, 189, 0.7f));
    drawText("MINIMAP", mapX + 10.0f, mapY + 8.0f, 1.7f, rgb(238, 247, 255));
  }

  bool isFreyaOccludedByBuilding(const Building &b) const {
    const float freyaDepth = freya.pos.x + freya.pos.y + 0.27f;
    const float buildingDepth = b.x + b.y + b.d + 0.1f;
    if (freyaDepth >= buildingDepth - 0.03f) {
      return false;
    }

    const Vec2 B = worldToScreen(b.x + b.w, b.y, 0.0f);
    const Vec2 C = worldToScreen(b.x + b.w, b.y + b.d, 0.0f);
    const Vec2 D = worldToScreen(b.x, b.y + b.d, 0.0f);
    const Vec2 B2 = worldToScreen(b.x + b.w, b.y, b.h);
    const Vec2 C2 = worldToScreen(b.x + b.w, b.y + b.d, b.h);
    const Vec2 D2 = worldToScreen(b.x, b.y + b.d, b.h);

    const std::array<Vec2, 3> probes = {
      worldToScreen(freya.pos.x, freya.pos.y, 3.0f),
      worldToScreen(freya.pos.x, freya.pos.y, 8.0f),
      worldToScreen(freya.pos.x, freya.pos.y, 13.0f)
    };

    for (const Vec2 &probe : probes) {
      if (pointInQuad(probe, B2, C2, C, B) || pointInQuad(probe, C2, D2, D, C)) {
        return true;
      }
    }
    return false;
  }

  void drawFreyaOcclusionCutout() const {
    float strongest = 0.0f;
    float roofHint = 0.0f;
    for (const Building &b : buildings) {
      if (!isFreyaOccludedByBuilding(b)) {
        continue;
      }
      const float cx = b.x + b.w * 0.5f;
      const float cy = b.y + b.d * 0.5f;
      const float reach = std::max(3.0f, (b.w + b.d) * 0.55f);
      const float d = std::sqrt(distSq(freya.pos, {cx, cy}));
      const float t = clampf(1.0f - d / reach, 0.0f, 1.0f);
      strongest = std::max(strongest, t);
      roofHint = std::max(roofHint, b.h);
    }

    if (strongest <= 0.01f) {
      return;
    }

    const Vec2 p = worldToScreen(freya.pos.x, freya.pos.y);
    const float r = 15.0f + strongest * 11.0f;
    drawEllipse(p.x, p.y - 8.0f, r * 1.02f, r * 0.74f, rgb(198, 238, 255, 0.16f + strongest * 0.25f), 28);
    drawEllipseOutline(p.x, p.y - 8.0f, r * 1.08f, r * 0.79f, rgb(220, 246, 255, 0.92f), 2.0f, 32);
    drawEllipseOutline(p.x, p.y - 8.0f, r * 0.66f, r * 0.47f, rgb(170, 222, 255, 0.68f), 1.6f, 26);

    const float lift = std::max(34.0f, roofHint * 0.22f);
    const Vec2 marker = worldToScreen(freya.pos.x, freya.pos.y, lift);
    drawLine({marker.x, marker.y - 16.0f}, {marker.x, marker.y + 3.0f}, rgb(229, 245, 255, 0.8f), 2.0f);
    drawTriangle(
      {marker.x - 4.0f, marker.y - 16.0f},
      {marker.x + 4.0f, marker.y - 16.0f},
      {marker.x, marker.y - 21.0f},
      rgb(229, 245, 255, 0.85f)
    );
    drawEllipse(marker.x, marker.y + 5.0f, 3.2f, 2.4f, rgb(28, 28, 28, 0.82f), 16);
  }

  void drawWorld() {
    std::vector<RenderItem> items;
    items.reserve(buildings.size() + trees.size() + shrubs.size() + streetLights.size() + poops.size() + puddles.size() + dogs.size() + 1);

    for (int i = 0; i < static_cast<int>(buildings.size()); i += 1) {
      const Building &b = buildings[static_cast<size_t>(i)];
      const float cx = b.x + b.w * 0.5f;
      const float cy = b.y + b.d * 0.5f;
      if (!inCameraRange(cx, cy, b.w + 4.0f, b.d + 4.0f)) {
        continue;
      }
      items.push_back({b.x + b.y + b.d + 0.1f, RenderType::Building, i});
    }
    for (int i = 0; i < static_cast<int>(trees.size()); i += 1) {
      const Tree &t = trees[static_cast<size_t>(i)];
      if (!inCameraRange(t.x, t.y, 4.0f, 4.0f)) {
        continue;
      }
      items.push_back({t.x + t.y + 0.14f, RenderType::Tree, i});
    }
    for (int i = 0; i < static_cast<int>(shrubs.size()); i += 1) {
      const Shrub &s = shrubs[static_cast<size_t>(i)];
      if (!inCameraRange(s.x, s.y, 3.0f, 3.0f)) {
        continue;
      }
      items.push_back({s.x + s.y + 0.16f, RenderType::Shrub, i});
    }
    for (int i = 0; i < static_cast<int>(puddles.size()); i += 1) {
      const VomitPuddle &p = puddles[static_cast<size_t>(i)];
      if (!inCameraRange(p.pos.x, p.pos.y, 2.0f, 2.0f)) {
        continue;
      }
      items.push_back({p.pos.x + p.pos.y + 0.2f, RenderType::Vomit, i});
    }
    for (int i = 0; i < static_cast<int>(poops.size()); i += 1) {
      const Poop &p = poops[static_cast<size_t>(i)];
      if (!inCameraRange(p.pos.x, p.pos.y, 2.0f, 2.0f)) {
        continue;
      }
      items.push_back({p.pos.x + p.pos.y + 0.21f, RenderType::Poop, i});
    }
    for (int i = 0; i < static_cast<int>(dogs.size()); i += 1) {
      const Dog &d = dogs[static_cast<size_t>(i)];
      if (!inCameraRange(d.pos.x, d.pos.y, 3.0f, 3.0f)) {
        continue;
      }
      items.push_back({d.pos.x + d.pos.y + 0.25f, RenderType::Dog, i});
    }

    items.push_back({freya.pos.x + freya.pos.y + 0.27f, RenderType::Freya, 0});

    std::sort(items.begin(), items.end(), [](const RenderItem &a, const RenderItem &b) {
      return a.depth < b.depth;
    });

    for (const RenderItem &item : items) {
      switch (item.type) {
        case RenderType::Building:
          drawBuilding(buildings[static_cast<size_t>(item.index)]);
          break;
        case RenderType::Tree:
          drawTree(trees[static_cast<size_t>(item.index)]);
          break;
        case RenderType::Shrub:
          drawShrub(shrubs[static_cast<size_t>(item.index)]);
          break;
        case RenderType::Light:
          drawStreetLight(streetLights[static_cast<size_t>(item.index)]);
          break;
        case RenderType::Vomit:
          drawPuddle(puddles[static_cast<size_t>(item.index)]);
          break;
        case RenderType::Poop:
          drawPoop(poops[static_cast<size_t>(item.index)]);
          break;
        case RenderType::Dog:
          drawDog(dogs[static_cast<size_t>(item.index)], false);
          break;
        case RenderType::Freya:
          drawDog(
            {
              freya.pos,
              freya.facing,
              freya.screenFacing,
              0.0f,
              0.0f,
              0.0f,
              freya.step,
              1.1f,
              1.05f,
              0.92f,
              1.14f,
              1.02f,
              rgb(17, 17, 17)
            },
            true
          );
          break;
      }
    }
  }

  void render() {
    updateMaterialLighting(false);
    setProjection2D();
    glClearColor(0.15f, 0.23f, 0.2f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    drawBackground();
    drawGround();
    drawDogPark();
    drawStreetLightPools();
    drawWorld();
    drawFreyaOcclusionCutout();
    drawBarkPulses();
    drawLabels();
    drawVignette();
    drawHUD();
    drawMiniMap();
  }
};

}  // namespace

int main() {
  Game game;
  if (!game.init()) {
    return 1;
  }

  game.run();
  return 0;
}
