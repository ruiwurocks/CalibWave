function fileName = exportAxes(ax, fileBase, fileType)
%EXPORTAXES Export an axes using consistent project settings.

fileType = lower(string(fileType));
if ~ismember(fileType, ["pdf", "jpg", "jpeg", "png"])
    fileType = "png";
end
fileName = char(string(fileBase) + "." + fileType);
if fileType == "pdf"
    exportgraphics(ax, fileName, 'ContentType', 'vector');
else
    exportgraphics(ax, fileName, 'Resolution', 300);
end

end
