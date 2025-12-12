main:
	odin run . -out:Bogwalker.exe -subsystem:console -debug -max-error-count:8 -show-timings
debug:
	odin build . -out:Bogwalker.exe -subsystem:console -debug -max-error-count:8
	remedybg -g debug.rdbg
run:
	odin run . -out:Bogwalker.exe -subsystem:console -debug -max-error-count:8 # -o:speed
release:
	./build.exe -release
trace:
	sh -c "tracy-profiler.exe -a localhost" & \
		sh -c "odin run . -out:"Bogwalker.exe" -subsystem:console -debug -define:TRACY_ENABLE=true -define:BOUNDED_RUNTIME=true"
