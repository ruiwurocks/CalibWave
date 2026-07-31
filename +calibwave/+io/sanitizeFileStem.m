function stem = sanitizeFileStem(textValue)
%SANITIZEFILESTEM Convert display text into a stable file-name stem.

stem = string(textValue);
stem = regexprep(stem, '^\s+|\s+$', '');
stem = regexprep(stem, '(\d)\.(\d)', '$1_$2');
stem = regexprep(stem, '[^\w\d\-]+', '_');
stem = regexprep(stem, '_+', '_');
stem = regexprep(stem, '^_|_$', '');

if strlength(stem) == 0
    stem = "untitled";
end

end
