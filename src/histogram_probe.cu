#include <cub/device/device_histogram.cuh>
#include <cub/version.cuh>
#include <cuda_runtime.h>
#include "histogram_oracle.hpp"
#include <chrono>
#include <iostream>
#include <numeric>
#include <string>

void cuda_check(cudaError_t e){if(e!=cudaSuccess)throw std::runtime_error(cudaGetErrorString(e));}
template<class T> struct Device {
  T* p=nullptr;
  explicit Device(size_t n){cuda_check(cudaMalloc(&p,std::max(size_t{1},n)*sizeof(T)));}
  Device(const Device&)=delete; Device& operator=(const Device&)=delete;
  ~Device(){cudaFree(p);}
};
template<class Sample,class Count=int>
bool run_case(const std::string& name,const std::vector<Sample>& samples,const std::vector<int>& levels,bool even,bool timing){
  const size_t bins=levels.size()-1;
  if(samples.size()>static_cast<size_t>(std::numeric_limits<Count>::max()))throw std::overflow_error("counter contract");
  const auto expected=contract::histogram<Sample,Count>(samples,levels);
  Device<Sample> input(samples.size());Device<int> edges(levels.size());Device<Count> output(bins+2);
  const Count guard=1234567;
  std::vector<Count> host(bins+2,guard);
  cuda_check(cudaMemcpy(input.p,samples.data(),samples.size()*sizeof(Sample),cudaMemcpyHostToDevice));
  cuda_check(cudaMemcpy(edges.p,levels.data(),levels.size()*sizeof(int),cudaMemcpyHostToDevice));
  cuda_check(cudaMemcpy(output.p,host.data(),host.size()*sizeof(Count),cudaMemcpyHostToDevice));
  size_t bytes=0;
  auto invoke=[&](void* temp){
    if(even)return cub::DeviceHistogram::HistogramEven(temp,bytes,input.p,output.p+1,static_cast<int>(levels.size()),levels.front(),levels.back(),static_cast<int>(samples.size()));
    return cub::DeviceHistogram::HistogramRange(temp,bytes,input.p,output.p+1,static_cast<int>(levels.size()),edges.p,static_cast<int>(samples.size()));
  };
  cuda_check(invoke(nullptr));Device<char> workspace(bytes);
  cuda_check(invoke(workspace.p));cuda_check(cudaDeviceSynchronize());
  cuda_check(cudaMemcpy(host.data(),output.p,host.size()*sizeof(Count),cudaMemcpyDeviceToHost));
  const bool guards=host.front()==guard && host.back()==guard;
  const bool correct=guards && std::equal(expected.begin(),expected.end(),host.begin()+1);
  const auto total=std::accumulate(host.begin()+1,host.end()-1,int64_t{0});
  const auto wanted=std::accumulate(expected.begin(),expected.end(),int64_t{0});
  std::cout<<"{\"case\":\""<<name<<"\",\"api\":\""<<(even?"even":"range")<<"\",\"cub_version\":"<<CUB_VERSION
           <<",\"n\":"<<samples.size()<<",\"bins\":"<<bins<<",\"sample_bytes\":"<<sizeof(Sample)
           <<",\"signed\":"<<(std::is_signed_v<Sample>?"true":"false")<<",\"count_bytes\":"<<sizeof(Count)
           <<",\"correct\":"<<(correct?"true":"false")<<",\"guards\":"<<(guards?"true":"false")
           <<",\"count\":"<<total<<",\"expected_count\":"<<wanted<<",\"workspace_bytes\":"<<bytes;
  if(timing && correct){
    for(int i=0;i<10;++i)cuda_check(invoke(workspace.p));
    cuda_check(cudaDeviceSynchronize());
    cudaEvent_t start,end;cuda_check(cudaEventCreate(&start));cuda_check(cudaEventCreate(&end));
    std::cout<<",\"raw_ms\":[";
    for(int i=0;i<31;++i){
      cuda_check(cudaEventRecord(start));for(int j=0;j<20;++j)cuda_check(invoke(workspace.p));
      cuda_check(cudaEventRecord(end));cuda_check(cudaEventSynchronize(end));
      float ms;cuda_check(cudaEventElapsedTime(&ms,start,end));std::cout<<(i?",":"")<<ms/20;
    }
    cuda_check(cudaEventDestroy(start));cuda_check(cudaEventDestroy(end));std::cout<<"]";
  }
  if(!correct){
    std::cout<<",\"mismatches\":[";int count=0;
    for(size_t i=0;i<bins && count<8;++i)if(expected[i]!=host[i+1]){
      std::cout<<(count++?",":"")<<"{\"bin\":"<<i<<",\"expected\":"<<expected[i]<<",\"actual\":"<<host[i+1]<<"}";
    }std::cout<<"]";
  }
  std::cout<<"}\n";return correct;
}

template<class T> std::vector<T> domain(int low,int high){std::vector<T> x;for(int i=low;i<high;++i)x.push_back(static_cast<T>(i));return x;}
std::vector<int> edges(int low,int high){return domain<int>(low,high+1);}
int main(int argc,char** argv){try{
  const std::string mode=argc>1?argv[1]:"check";int failures=0;
  if(mode=="minimal"){
    return run_case<int8_t>("signed-minimal",{-60,-1,10,63},{-60,-29,2,33,64},true,false)?0:2;
  }
  if(mode=="bench"){
    std::vector<uint8_t> u(1<<20);std::vector<int32_t> w(1<<20);std::vector<int8_t> s(1<<20);
    for(size_t i=0;i<u.size();++i){u[i]=static_cast<uint8_t>(i*73);w[i]=static_cast<int>(u[i]);s[i]=static_cast<int8_t>(i%64);}
    failures+=!run_case("unsigned-fast",u,edges(0,256),true,true);
    failures+=!run_case("int32-control",w,edges(0,256),true,true);
    failures+=!run_case("signed-positive",s,edges(0,64),true,true);
  }else if(mode=="check"){
    for(bool even:{false,true}){
      failures+=!run_case<int8_t>("signed-minimal",{-60,-1,10,63},{-60,-29,2,33,64},even,false);
      failures+=!run_case<int8_t>("empty",{}, {-128,0,128},even,false);
      failures+=!run_case<int8_t>("endpoints",{-128,-127,-1,0,63,64,127},{-128,-64,0,64,128},even,false);
      for(int bins:{127,128,129,255,256,257}){
        failures+=!run_case<int8_t>("int8-bin-boundary-"+std::to_string(bins),domain<int8_t>(-128,128),edges(-128,-128+bins),even,false);
        failures+=!run_case<uint8_t>("uint8-bin-boundary-"+std::to_string(bins),domain<uint8_t>(0,256),edges(0,bins),even,false);
      }
      failures+=!run_case<int16_t>("int16-full-domain",domain<int16_t>(-32768,32768),edges(-32768,32768),even,false);
      failures+=!run_case<int32_t>("int32-outside",{-1000,-60,-1,10,63,64,1000},{-60,-29,2,33,64},even,false);
      failures+=!run_case<int8_t,unsigned long long>("wide-counter",domain<int8_t>(-128,128),edges(-128,128),even,false);
      // Standard char is implementation-defined; record the signedness instead of assuming it.
      failures+=!run_case<char>("plain-char",domain<char>(0,64),edges(0,64),even,false);
    }
  }else throw std::invalid_argument("mode must be check, minimal, or bench");
  return failures?2:0;
}catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}}
