#ifndef XBOX_FILE_SYSTEM_H
#define XBOX_FILE_SYSTEM_H

#include <string>

namespace XeniOS {
namespace VFS {

/**
 * Wrapper for xbox VFS - handles Xbox file mounting: STFS, GDFX, etc.
 * Uses xe::vfs when the full Xenia VFS is linked.
 */
class XboxFileSystem {
public:
  XboxFileSystem();
  ~XboxFileSystem();

  // Maps a local host directory or ISO layout to a guest device name
  bool MountSymbolicLink(const std::string &targetDevice,
                         const std::string &hostPath);

  // Resolves an Xbox path to a host file descriptor
  int OpenFile(const std::string &guestPath, int accessFlags);

private:
  // Internal VFS state
};

} // namespace VFS
} // namespace XeniOS

#endif // XBOX_FILE_SYSTEM_H
