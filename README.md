# mengine-buildimage

Docker image and Kubernetes deployment configuration for benchmarking Mengine. The image builds mengine, mengine-benchmarks, Coq, Lean, and coqutil for running performance benchmarks.

The container will stay alive after completing benchmarks to allow you to pull any results off the container.