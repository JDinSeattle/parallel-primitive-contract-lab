#pragma once
#include <algorithm>
#include <cstdint>
#include <limits>
#include <stdexcept>
#include <type_traits>
#include <vector>

namespace contract {
// Independent CPU reference: interval comparisons, never CUB's dispatch/index path.
template<class Sample, class Count = std::int64_t>
std::vector<Count> histogram(const std::vector<Sample>& samples, const std::vector<int>& levels) {
  static_assert(std::is_integral_v<Sample> && sizeof(Sample) <= 4);
  static_assert(std::is_integral_v<Count>);
  if (levels.size() < 2 || !std::is_sorted(levels.begin(), levels.end()) ||
      std::adjacent_find(levels.begin(), levels.end()) != levels.end())
    throw std::invalid_argument("levels must be strictly increasing");
  std::vector<Count> result(levels.size()-1, 0);
  for (auto x : samples) {
    const auto value=static_cast<std::int64_t>(x);
    const auto it=std::upper_bound(levels.begin(), levels.end(), value);
    if (it==levels.begin() || it==levels.end()) continue;
    auto& count=result[static_cast<std::size_t>(it-levels.begin()-1)];
    if(count==std::numeric_limits<Count>::max()) throw std::overflow_error("counter overflow");
    ++count;
  }
  return result;
}
}
