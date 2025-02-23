package bogwalker
import "core:fmt"
import "core:os"
import "core:math"
import "core:strconv"
@(require_results)
default_settings::proc()->(settings:Settings) {
	settings.display=auto_cast DEFAULT_DISPLAY_SETTING
	settings.audio=DEFAULT_AUDIO_SETTING
	settings.window_size={1280,720}
	return settings }
@(require_results)
default_highscores::proc()->(highscores:Highscores) {
	highscores[int(Difficulty.BEGINNER)]=math.F32_MAX
	highscores[int(Difficulty.EASY)]=math.F32_MAX
	highscores[int(Difficulty.MEDIUM)]=math.F32_MAX
	highscores[int(Difficulty.HARD)]=math.F32_MAX
	return highscores }
@(require_results)
default_savefile::proc()->(savefile:Savefile) {
	savefile.highscores=default_highscores()
	savefile.settings=default_settings()
	return savefile }
init_savefile::proc() {
	savefile:Savefile=load_savefile()
	state.settings=savefile.settings
	state.highscores=savefile.highscores }
load_savefile::proc()->(savefile:Savefile) {
	handle,err:=os.open("savefile",os.O_RDWR)
	if err!=os.General_Error.None { return default_savefile() }
	defer os.close(handle)
	_,err=os.read_ptr(handle,&savefile,size_of(Savefile))
	if err!=os.General_Error.None { return default_savefile() }
	return savefile }
save_savefile::proc() {
	handle,err:=open_or_make("savefile")
	if err!=os.General_Error.None do return
	defer os.close(handle)
	savefile:Savefile={ settings=state.settings,highscores=state.highscores }
	_,err=os.write_ptr(handle,&savefile,size_of(Savefile)) }