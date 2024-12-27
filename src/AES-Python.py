from Crypto.Cipher import AES

def pad(data):
    # Padding to ensure the data is a multiple of 16 bytes
    padding_length = 16 - len(data) % 16
    return data + bytes([padding_length] * padding_length)

def encrypt_iv_with_numbers(hex_key, hex_iv):
    # Convert hex strings to bytes
    key = bytes.fromhex(hex_key)
    iv = bytes.fromhex(hex_iv)
    
    # Ensure the key is 16 bytes (128 bits) long
    if len(key) != 16:
        raise ValueError("Key must be 128 bits (32 hex characters) long.")
    
    # Ensure the IV is 16 bytes (128 bits) long
    if len(iv) != 16:
        raise ValueError("IV must be 128 bits (32 hex characters) long.")
    
    encrypted_outputs = []

    for i in range(100):
        iv_int = int.from_bytes(iv, byteorder='big')
        new_iv_int = iv_int + i
        new_iv = new_iv_int.to_bytes(16, byteorder='big')
        print(new_iv.hex())
        data_to_encrypt = new_iv  # Use only 14 bytes of IV and 2 bytes for the number
        cipher = AES.new(key, AES.MODE_ECB)
        ct_bytes = cipher.encrypt(data_to_encrypt)
        ct_hex = ct_bytes.hex()
        encrypted_outputs.append(ct_hex)
    
    return encrypted_outputs


# Example usage
hex_key = "0123456789abcdef0123456789abcdef"  # Example 128-bit key in hex
hex_iv =  "0123456789abcdef0123456700000000"  # Example 128-bit IV in hex

encrypted_data = encrypt_iv_with_numbers(hex_key, hex_iv)
for i, encrypted in enumerate(encrypted_data):
    print(f"IV + {i}: {encrypted}")