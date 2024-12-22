# Low Latency AES-GCM Encryption for Network Packets

This project is part of the Digital System Design course at Ferdowsi University of Mashhad. The goal is to design and implement a low latency AES-GCM encryption system for securing network packets.

## Project Overview

AES-GCM (Advanced Encryption Standard - Galois/Counter Mode) is a widely used encryption algorithm that provides both confidentiality and data integrity. This project focuses on optimizing AES-GCM for low latency, making it suitable for high-speed network applications.

## Features

- **Parallel AES Instances**: The design utilizes 100 parallel AES instances to achieve high throughput and low latency.
- **Configurable Key and IV**: Supports dynamic key and initialization vector (IV) configuration.
- **Verilog Implementation**: The encryption system is implemented in Verilog, suitable for FPGA synthesis.
- **Testbench Included**: A comprehensive testbench is provided to verify the functionality and performance of the design.

## File Structure

- `src/`: Contains the Verilog source files for the AES-GCM encryption system.
  - `AES-GCM.v`: The main module implementing the AES-GCM encryption.
  - `aes.v`: Core AES encryption logic.
  - `gf.v`: Galois/Counter Mode logic.
- `testbench/`: Contains testbench files for simulation and verification.
  - `aes_gcm_tb.v`: Testbench for the AES-GCM encryption system.
- `docs/`: Documentation and reports related to the project.
  - `report.pdf`: Detailed project report.

## Getting Started

### Prerequisites

- **Vivado**: Xilinx Vivado Design Suite for synthesis and simulation.
- **ModelSim**: For running simulations (optional).

### Running the Simulation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/low-latency-aes-gcm.git
   cd low-latency-aes-gcm
   ```

2. Open the project in Vivado or your preferred Verilog simulator.

3. Run the testbench:
   - Load `aes_gcm_tb.v` in the simulator.
   - Execute the simulation to verify the design.

### Synthesis

To synthesize the design for an FPGA:

1. Open the project in Vivado.
2. Set the target FPGA device.
3. Run the synthesis and implementation processes.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request for any improvements or bug fixes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Dr.Mohammad-Hossein Farzam for guidance and support.

## Contact

For any questions or feedback, please contact US.

