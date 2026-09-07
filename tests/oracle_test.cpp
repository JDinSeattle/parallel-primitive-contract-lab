#include "histogram_oracle.hpp"
#include <iostream>
int main() {
  int checked=0;
  auto check=[&](bool b){if(!b)throw std::runtime_error("oracle contract failed");++checked;};
  check(contract::histogram(std::vector<int>{-61,-60,-30,-1,0,30,63,64}, {-60,-30,0,30,64})==std::vector<int64_t>({1,2,1,2}));
  check(contract::histogram(std::vector<int>{}, {-1,0,1})==std::vector<int64_t>({0,0}));
  for(int size=1;size<=256;++size){
    std::vector<int8_t> v; std::vector<int> edges;
    for(int i=0;i<size;++i){v.push_back(static_cast<int8_t>(i-128));edges.push_back(i-128);}
    edges.push_back(size-128);
    check(contract::histogram(v,edges)==std::vector<int64_t>(size,1));
  }
  for(auto edges:std::vector<std::vector<int>>{{},{0},{1,0},{0,0,1}}){
    try{contract::histogram(std::vector<int>{},edges);check(false);}catch(const std::invalid_argument&){++checked;}
  }
  try{contract::histogram<int,uint8_t>(std::vector<int>(256,0),{0,1});check(false);}catch(const std::overflow_error&){++checked;}
  std::cout<<"{\"status\":\"passed\",\"checks\":"<<checked<<"}\n";
}
