function bringToFront(fig)
%BRINGTOFRONT Restore and focus a UI figure after dialogs or callbacks.

if isempty(fig) || ~isvalid(fig)
    return;
end

try
    fig.Visible = 'on';
catch
end

try
    fig.WindowState = 'normal';
catch
end

drawnow;

try
    figure(fig);
catch
end

drawnow;

end
