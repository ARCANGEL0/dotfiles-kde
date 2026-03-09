const setOpacity = (window) => {
    window.opacity = readConfig("userSetOpacity", 75) / 100;
};

workspace.windowAdded.connect((window) => {
    window.normalWindow && setOpacity(window);
});