-- Performance Benchmarking Query

-- Measure the time taken to retrieve the top 10 most viewed posts with their respective user details and tags
SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.ViewCount, 
    u.DisplayName AS OwnerDisplayName, 
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UNNEST(STRING_TO_ARRAY(p.Tags, '> <')) AS tag_name ON TRUE
JOIN 
    Tags t ON TRIM(tag_name) = t.TagName
WHERE 
    p.PostTypeId = 1  -- Only questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.ViewCount DESC
LIMIT 10;

