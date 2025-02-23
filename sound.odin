package bogwalker
import "core:strings"
import "vendor:miniaudio"
init_sound::proc() {
	state.ma_rm_conf=miniaudio.resource_manager_config_init()
	state.ma_rm_conf.decodedFormat=miniaudio.format.f32
	state.ma_rm_conf.decodedChannels=0
	state.ma_rm_conf.decodedSampleRate=48000
	state.ma_res=miniaudio.resource_manager_init(&state.ma_rm_conf,&state.ma_rm)
	if state.ma_res!=miniaudio.result.SUCCESS { return }
	state.ma_res=miniaudio.context_init(nil,0,nil,&state.ma_ctx)
	if state.ma_res!=miniaudio.result.SUCCESS { return }
	state.ma_res=miniaudio.context_get_devices(&state.ma_ctx,&state.ma_dev_infos,&state.ma_dev_count,nil,nil)
	if state.ma_res!=miniaudio.result.SUCCESS { miniaudio.context_uninit(&state.ma_ctx); return }
	state.ma_dev_confs=make([^]miniaudio.device_config,state.ma_dev_count)
	state.ma_eng_confs=make([^]miniaudio.engine_config,state.ma_dev_count)
	state.ma_default_device_index=-1
	for i in 0..<state.ma_dev_count {
		state.ma_dev_confs[i]=miniaudio.device_config_init(miniaudio.device_type.playback)
		state.ma_dev_confs[i].playback.pDeviceID=&state.ma_dev_infos[i].id
		state.ma_dev_confs[i].playback.format=state.ma_rm.config.decodedFormat
		state.ma_dev_confs[i].playback.channels=0
		state.ma_dev_confs[i].sampleRate=state.ma_rm.config.decodedSampleRate
		state.ma_dev_confs[i].dataCallback=miniaudio.device_data_proc(audio_data_callback)
		state.ma_dev_confs[i].pUserData=&state.ma_engs[i]
		state.ma_res=miniaudio.device_init(nil,&state.ma_dev_confs[i],&state.ma_devs[i])
		if state.ma_res!=miniaudio.result.SUCCESS { return }
		dev_info:miniaudio.device_info
		miniaudio.device_get_info(&state.ma_devs[i],miniaudio.device_type.playback,&dev_info)
		if dev_info.isDefault { state.ma_default_device_index=int(i) }
		state.ma_eng_confs[i]=miniaudio.engine_config_init()
		state.ma_eng_confs[i].pDevice=&state.ma_devs[i]
		state.ma_eng_confs[i].pResourceManager=&state.ma_rm
		state.ma_eng_confs[i].noAutoStart=true
		state.ma_res=miniaudio.engine_init(&state.ma_eng_confs[i],&state.ma_engs[i])
		if state.ma_res!=miniaudio.result.SUCCESS { miniaudio.device_uninit(&state.ma_devs[i]); return } }
	for i in 0..<state.ma_dev_count {
		state.ma_res=miniaudio.engine_start(&state.ma_engs[i])
		if state.ma_res!=miniaudio.result.SUCCESS { return } }
	if state.ma_default_device_index!=-1 {
		state.ma_audio_engine=&state.ma_engs[state.ma_default_device_index]
		miniaudio.device_set_master_volume(&state.ma_devs[state.ma_default_device_index],f32(state.settings.audio)) }
	else {
		state.ma_audio_engine=&state.ma_engs[0] }
	play_sound("water",loop=true) }
load_sound::proc(filepath:string,duration:f32=-1)->(ptr:^Sound) {
	sound:Sound
	sound.name=name_from_path(filepath)
	sound.filepath=strings.clone(filepath)
	sound.cfilepath=strings.clone_to_cstring(filepath)
	sound.duration=duration
	// miniaudio.sound_init_from_file(pEngine=state.ma_audio_engine,pFilePath=strings.clone_to_cstring(filepath),flags={},pGroup=nil,pDoneFence=nil,pSound=&sound.sound)
	return map_insert(&state.sounds,sound.name,sound) }
audio_data_callback::proc(dev:^miniaudio.device,output,input:rawptr,frame_count:u32) {
	miniaudio.engine_read_pcm_frames((^miniaudio.engine)(dev.pUserData),output,u64(frame_count),nil) }
play_sound::proc(name:string,loop:bool=false) {
	sound:=&state.sounds[name]
	sound.start_time=read_timer(&state.timer)
	sound.loop=loop
	miniaudio.engine_play_sound(state.ma_audio_engine,sound.cfilepath,nil) }
set_audio_volume::proc(volume:f16) {
	miniaudio.device_set_master_volume(&state.ma_devs[state.ma_default_device_index],f32(volume)) }
watch_sound::proc(name:string) {
	sound:=&state.sounds[name]
	if sound.loop do if (state.net_time-sound.start_time)>=sound.duration do play_sound(name,sound.loop) }
sound_tick::proc() {
	watch_sound("water") }