pragma solidity ^0.4.8;

/*
  CORE PRINCIPLES:

    - All paths lead to some hash (null or not null)
    - Data layer
      - Allows setting the hash of a path
      - Allows getting the hash of a path
    - Verification layer
      - Cannot submit data unless a public key has been set
    - Security layer
      - Owner can read, write to any path
      - Can only write to a path which you have been granted access to write to
      - Can only read from a path which you have been granted access to read from
*/
contract IPFSStorage {

  /* ----------------------------------------------------------------------- */
  /* MODIFIERS */
  /* ----------------------------------------------------------------------- */

  modifier onlyOwner() {
    if (msg.sender != owner) throw;
    _;
  }

  modifier writable(string path) {
    if (msg.sender != owner && !allowedWrite(msg.sender, path)) throw;
    _;
  }

  modifier readable(string path) {
    if (msg.sender != owner && !allowedRead(msg.sender, path)) throw;
    _;
  }

  /* ----------------------------------------------------------------------- */
  /* DATA STRUCTURES */
  /* ----------------------------------------------------------------------- */

  struct Set {
    string[] items;
  }

  struct IpfsHash {
    bytes32 part1;
    bytes32 part2;
    mapping(address => uint) access_control;
  }

  /* Contract owner */
  address public owner;

  /* Public key to encrypt data */
  IpfsHash publicKey;

  /* Used for indexing */
  Set paths;

  /* Specific user's available paths */
  mapping (address => Set) user_paths;

  /* Record location */
  mapping (string => IpfsHash) hashes;

  /* ----------------------------------------------------------------------- */
  /* EXTERNAL FUNCTIONS */
  /* ----------------------------------------------------------------------- */

  function IPFSStorage(bytes32 pub_1, bytes32 pub_2) {
    owner = msg.sender;
    publicKey = IpfsHash(pub_1, pub_2);
  }

  /* ONLY ACCESSIBLE BY ENTITIES ABLE TO PROXY-RE-ENCRYPT / DATA OWNER */
  function add(string path, bytes32 hash1, bytes32 hash2) writable(path) {
    /* Find the index of the path */
    uint index = contains(paths, path);

    /* Update path */
    insert(paths, path);
    insert(user_paths[msg.sender], path);
    hashes[path] = IpfsHash({
      part1: hash1,
      part2: hash2
    });
  }

  /* ONLY ACCESSIBLE BY OWNER */
  function giveWrite(address writer, string path) onlyOwner {
    allowWrite(writer, path);
  }

  /* ONLY ACCESSIBLE BY OWNER */
  function giveRead(address writer, string path) onlyOwner {
    allowRead(writer, path);
  }

  /* CONSTANT FUNCTIONS */

  /* ONLY ACCESSIBLE BY ENTITIES ABLE TO PROXY-RE-ENCRYPT / DATA OWNER */
  function get(string path) readable(path) constant returns (bytes32, bytes32) {
    /* Return hash of path */
    IpfsHash h = hashes[path];
    return (h.part1, h.part2);
  }

  /* ACCESSIBLE BY ANY PARTY */
  function getIndex(uint index) constant returns (string) {
    /* Get the user's available paths */
    Set my_paths = user_paths[msg.sender];

    /* Check index is valid and return blank if not */
    if (index < 0 || index >= size(my_paths))
      return "";

    /* Return blank for invalid */
    return my_paths.items[index];
  }

  /* ACCESSIBLE BY ANY PARTY */
  function size() constant returns (uint) {
    /* The size of the user's available paths */
    return size(user_paths[msg.sender]);
  }

  /* ACCESSIBLE BY ANY PARTY */
  function canWrite(address writer, string path) constant returns (bool) {
    return writer == owner || allowedWrite(writer, path);
  }

  function canRead(address writer, string path) constant returns (bool) {
    return writer == owner || allowedRead(writer, path);
  }

  /* ----------------------------------------------------------------------- */
  /* SET LOGIC */
  /* ----------------------------------------------------------------------- */

  function insert(Set storage set, string path) internal {
    if (contains(set, path) == size(set))
      set.items.push(path);
      set.items.length++;
  }

  function remove(Set storage set, string path) internal {
    uint index = contains(set, path);
    if (index != size(set)) {
      set.items[index] = set.items[size(set) - 1];
      set.items[size(set) - 1] = '';
      set.items.length--;
    }
  }

  function contains(Set storage set, string path) internal returns (uint) {
    for (uint i = 0; i < size(set); i++)
      if (stringEqual(set.items[i], path))
        return i;
    return size(set);
  }

  function size(Set storage set) internal returns (uint) {
    return set.items.length;
  }

   /* ----------------------------------------------------------------------- */
  /* ACCESS CONTROL */
  /*
     No access by default (0)
     R = 1, W = 2, RL = 4, WL = 8
     mapping(uint => mapping(address => uint)) access_control

      1: R            2: W            3: R, W            4: RL
      5: R, RL        6: W, RL        7: R, W, RL        8: WL
      9: R, WL       10: W, WL       11: R, W, WL       12: RL, WL
     13: R, RL, WL   14: W, RL, WL   15: R, W, RL, WL
  */
  /* ----------------------------------------------------------------------- */

  /* VIEW ACCESS */

  function allowedRead(address addr, string path) internal returns (bool) {
    IpfsHash h = hashes[path];
    uint access = h.access_control[addr];
    access = access % 2;
    return (access == 1);
  }

  function allowedWrite(address addr, string path) internal returns (bool) {
    IpfsHash h = hashes[path];
    uint access = h.access_control[addr];
    access = access % 4;
    return (access >= 2);
  }

  /*function allowedReadLog(address addr, string path) internal returns (bool) {
    IpfsHash h = hashes[path];
    uint access = h.access_control[addr];
    access = access % 8;
    return (access >= 4);
  }*/

  /*function allowedWriteLog(address addr, string path) internal returns (bool) {
    IpfsHash h = hashes[path];
    uint access = h.access_control[addr];
    access = access % 16;
    return (access >= 8);
  }*/

  /* ADD ACCESS */

  function allowRead(address addr, string path) internal {
    if (!allowedRead(addr, path)) {
      IpfsHash h = hashes[path];
      h.access_control[addr] += 1;
    }
  }

  function allowWrite(address addr, string path) internal {
    if (!allowedWrite(addr, path)) {
      IpfsHash h = hashes[path];
      h.access_control[addr] += 2;
    }
  }

  /*function allowReadLog(address addr, string path) internal {
    if (!allowedReadLog(addr, path)) {
      IpfsHash h = hashes[path];
      h.access_control[addr] += 4;
    }
  }*/

  /*function allowWriteLog(address addr, string path) internal {
    if (!allowedWriteLog(addr, path)) {
      IpfsHash h = hashes[path];
      h.access_control[addr] += 8;
    }
  }*/

  /* REMOVE ACCESS */

  function removeRead(address addr, string path) internal {
    if (allowedRead(addr, path)) {
      IpfsHash h = hashes[path];
      h.access_control[addr] -= 1;
    }
  }

  function removeWrite(address addr, string path) internal {
    if (allowedWrite(addr, path)) {
      IpfsHash h = hashes[path];
      h.access_control[addr] -= 2;
    }
  }

  /*function removeReadLog(address addr, string path) internal {
    if (allowedReadLog(addr, path)) {
      IpfsHash h = hashes[path];
      h.access_control[addr] -= 4;
    }
  }*/

  /*function removeWriteLog(address addr, string path) internal {
    if (allowedWriteLog(addr, path)) {
      IpfsHash h = hashes[path];
      h.access_control[addr] -= 8;
    }
  }*/

  /* ----------------------------------------------------------------------- */
  /* STRING LOGIC */
  /* ----------------------------------------------------------------------- */

  function stringSlice(string s, uint start, uint end) internal returns (string) {
    bytes memory sBytes = bytes(s);
    bytes memory out = new bytes(end - start);
    for (uint i = 0; i < end; i++) {
      out[i] = sBytes[start + i];
    }
    return string(out);
  }

  function stringFindSeparator(string s, byte separator) internal returns (bool[]) {
    bool[] memory out;
    bytes memory sBytes;

    uint left = 0;
    for (uint i = 0; i < sBytes.length; i++) {
      if (sBytes[i] == separator) {
        out[i] = true;
        left = i + 1;
      }
    }
    return out;
  }

  function stringEqual(string a, string b) internal returns (bool) {
    bytes memory _a = bytes(a);
    bytes memory _b = bytes(b);
    if (_a.length != _b.length)
			return false;
		for (uint i = 0; i < _a.length; i ++)
			if (_a[i] != _b[i])
				return false;
		return true;
  }

  /* ----------------------------------------------------------------------- */
  /* UTILS */
  /* ----------------------------------------------------------------------- */

}
