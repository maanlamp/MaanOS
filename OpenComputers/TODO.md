# TODO list for MaanOS development

1) [x] Make a super tiny safe live kernel (safe as in: wrap all code in a pcall to enable and ensure error handling, live as in: can be hotswapped to allow in-OS development)
2) [ ] Make and start-up system API's (Array, Class, Inspect)
3) [ ] Separate OS functionality into services
   1) [ ] ProcessService (only place to handle processes (memory management, handle crashes))
   2) [ ] FilesystemService (only place to communicate with the fs)
   3) [ ] GraphicsService (only place to communicate with the GPU)
   4) [ ] InternetService (only place to communicate with the internet)
   5) [ ] WindowService (only place to handle windows)
4) [ ] Desktop
5) [ ] Warden (Process Manager)
6) [ ] Terminal (CLI)
7) [ ] Pilgrim (File Explorer)
8) [ ] Prose (IDE)