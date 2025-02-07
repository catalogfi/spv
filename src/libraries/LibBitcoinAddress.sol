// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library BitcoinAddressEncoder {
    // Base58 alphabet
    bytes constant ALPHABET_58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
    
    // Bech32 alphabet
    bytes constant ALPHABET_32 = "qpzry9x8gf2tvdw0s3jn54khce6mua7l";

    /**
     * @notice Encodes a P2PKH or P2SH address in Base58Check format
     * @param data The raw bytes to encode (20 bytes pubkeyhash/scripthash)
     * @param version Version byte (0x00 for P2PKH mainnet, 0x05 for P2SH mainnet)
     * @return The Base58Check encoded address
     */
    function encodeBase58Check(bytes memory data, uint8 version) internal pure returns (string memory) {
        // Add version byte
        bytes memory payload = new bytes(21);
        payload[0] = bytes1(version);
        for(uint i = 0; i < 20; i++) {
            payload[i+1] = data[i];
        }
        
        // Calculate checksum (double SHA256)
        bytes32 hash1 = sha256(payload);
        bytes32 hash2 = sha256(abi.encodePacked(hash1));
        
        // Add 4 byte checksum
        bytes memory extended = new bytes(25);
        for(uint i = 0; i < 21; i++) {
            extended[i] = payload[i];
        }
        for(uint i = 0; i < 4; i++) {
            extended[21+i] = hash2[i];
        }

        // Convert to base58
        uint8[] memory digits = new uint8[](34);
        uint256 digitsLength;
        
        for(uint i = 0; i < extended.length; i++) {
            uint carry = uint8(extended[i]);
            for(uint j = 0; j < digitsLength; j++) {
                carry += uint(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }
            
            while(carry > 0) {
                digits[digitsLength] = uint8(carry % 58);
                digitsLength++;
                carry = carry / 58;
            }
        }

        // Build the final base58 string
        bytes memory result = new bytes(digitsLength);
        for(uint i = 0; i < digitsLength; i++) {
            result[i] = ALPHABET_58[digits[digitsLength - 1 - i]];
        }
        
        return string(result);
    }

    /**
     * @notice Encodes a native SegWit address in Bech32 format
     * @param witnessVersion Witness version (0 for P2WPKH/P2WSH)
     * @param data Witness program (20 bytes for P2WPKH, 32 bytes for P2WSH)
     * @param hrp Human readable prefix ("bc" for mainnet, "tb" for testnet)
     * @return The Bech32 encoded address
     */
    function encodeBech32(uint8 witnessVersion, bytes memory data, string memory hrp) internal pure returns (string memory) {
        // Convert witness program to 5-bit words
        uint8[] memory words = new uint8[]((data.length * 8 + 4) / 5);
        uint wordsLength = 0;
        
        // Add witness version
        words[wordsLength++] = witnessVersion;
        
        // Convert 8-bit bytes to 5-bit words
        uint buffer = 0;
        uint bits = 0;
        for(uint i = 0; i < data.length; i++) {
            buffer = (buffer << 8) | uint8(data[i]);
            bits += 8;
            while(bits >= 5) {
                bits -= 5;
                words[wordsLength++] = uint8((buffer >> bits) & 31);
            }
        }
        if(bits > 0) {
            words[wordsLength++] = uint8((buffer << (5 - bits)) & 31);
        }

        // Create checksum
        bytes memory checksumInput = new bytes(2 + bytes(hrp).length + wordsLength);
        uint pos = 0;
        for(uint i = 0; i < bytes(hrp).length; i++) {
            checksumInput[pos++] = bytes(hrp)[i];
        }
        checksumInput[pos++] = 0x01; // separator
        for(uint i = 0; i < wordsLength; i++) {
            checksumInput[pos++] = bytes1(words[i]);
        }
        
        uint16 checksum = createChecksum(checksumInput);
        
        // Build final string
        bytes memory result = new bytes(bytes(hrp).length + 1 + wordsLength + 6);
        pos = 0;
        
        // Add HRP
        for(uint i = 0; i < bytes(hrp).length; i++) {
            result[pos++] = bytes(hrp)[i];
        }
        result[pos++] = 0x31; // separator "1"
        
        // Add data words
        for(uint i = 0; i < wordsLength; i++) {
            result[pos++] = ALPHABET_32[words[i]];
        }
        
        // Add checksum
        for(uint i = 0; i < 6; i++) {
            result[pos++] = ALPHABET_32[(checksum >> ((5 - i) * 5)) & 31];
        }
        
        return string(result);
    }

    /**
     * @notice Creates Bech32 checksum
     * @param data Input data including HRP and separator
     * @return 30-bit checksum value
     */
    function createChecksum(bytes memory data) private pure returns (uint16) {
        uint32 c = 1;
        for(uint i = 0; i < data.length; i++) {
            uint8 c0 = uint8(c >> 25);
            c = ((c & 0x1ffffff) << 5) ^ uint8(data[i]);
            if((c0 & 1) != 0) c ^= 0x3b6a57b2;
            if((c0 & 2) != 0) c ^= 0x26508e6d;
            if((c0 & 4) != 0) c ^= 0x1ea119fa;
            if((c0 & 8) != 0) c ^= 0x3d4233dd;
            if((c0 & 16) != 0) c ^= 0x2a1462b3;
        }
        return uint16(c & 0x3ffff);
    }
}
