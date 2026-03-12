#include "XboxFileSystem.h"
#include <stdio.h>

namespace XeniOS {
namespace VFS {

XboxFileSystem::XboxFileSystem() {}

XboxFileSystem::~XboxFileSystem() {}

bool XboxFileSystem::MountSymbolicLink(const std::string &targetDevice,
                                       const std::string &hostPath) {
  printf("[XeniOS VFS] Mounting device '%s' to host path '%s'\n",
         targetDevice.c_str(), hostPath.c_str());
  return true;
}

int XboxFileSystem::OpenFile(const std::string &guestPath, int accessFlags) {
  printf("[XeniOS VFS] OpenFile requested: %s\n", guestPath.c_str());
  return -1; // -1 means file not found for now
}

} // namespace VFS
} // namespace XeniOS
