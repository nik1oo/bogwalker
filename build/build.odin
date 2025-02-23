package build
import		"core:c/libc"
import		"core:fmt"
import		"core:os"
import		"core:slice"
import		"core:strings"
import		"core:sys/windows"
Flags::enum{TRACY,SANITIZE,RELEASE,VET}
flags:bit_set[Flags]={}
LOG:string:"\e[0;36m build |\e[0m"
main::proc() {
	assert(os.exists(`main.odin`))
	if slice.contains(os.args,"-tracy") do flags+={.TRACY}
	if slice.contains(os.args,"-sanitize") do flags+={.SANITIZE}
	if slice.contains(os.args,"-release") do flags+={.RELEASE}
	if slice.contains(os.args,"-vet") do flags+={.VET}
	fmt.println(LOG,"building Bogwalker...")
	libc.system("uname -o > uname.txt")
	uname_bytes,ok:=os.read_entire_file_from_filename("uname.txt")
	libc.system("rm uname.txt")
	defer delete(uname_bytes)
	uname:=strings.trim(string(uname_bytes),"\n")
	libc.system(fmt.ctprint(`rm -rf Bogwalker`,sep=""))
	libc.system(fmt.ctprint(`mkdir Bogwalker`,sep=""))
	libc.system(fmt.ctprint(`cp -r ./sounds ./Bogwalker/sounds`,sep=""))
	command:strings.Builder
	fmt.sbprint(&command,"odin build . -out:Bogwalker.exe ")
	if .RELEASE in flags do fmt.sbprint(&command,"-o:speed -warnings-as-errors -resource:resource.rc -subsystem:windows ",sep="")
	else do fmt.sbprint(&command,"-debug -o:none -max-error-count:12 ",sep="")
	if .VET in flags do fmt.sbprint(&command,"-vet-cast -vet-semicolon -vet-shadowing -vet-style -vet-unused -vet-tabs -vet-unused-variables -vet-packages:bogwalker -vet-unused-procedures -vet-unused-imports -vet-using-param -vet-using-stmt ")
	switch uname {
		case "Msys":
		case "GNU/Linux":
		fmt.sbprint(&command,"-extra-linker-flags:\"-lX11 -lrt -ldl -lpthread\" ") }
	if .TRACY in flags do fmt.sbprint(&command,"-define:TRACY_ENABLE=false ")
	if .SANITIZE in flags do fmt.sbprint(&command,"-sanitize:address ")
	fmt.println(LOG,"compile command:",strings.to_string(command))
	libc.system(strings.to_cstring(&command))
	libc.system(strings.clone_to_cstring(fmt.tprint(`mv Bogwalker.exe ./Bogwalker`))) }