WITH RecursiveTags AS (
    SELECT 
        Id,
        TagName,
        Count,
        1 AS Level
    FROM 
        Tags
    WHERE 
        IsModeratorOnly = 0 -- Get all non-moderator tags

    UNION ALL

    SELECT 
        t.Id,
        CONCAT(r.TagName, ', ', t.TagName) AS TagName,
        r.Count + t.Count AS Count,
        r.Level + 1
    FROM 
        Tags t
    JOIN 
        RecursiveTags r ON CHARINDEX(t.TagName, r.TagName) = 0
    WHERE 
        r.Level < 3 -- Limit the recursion depth to create combinations
)

SELECT 
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    STRING_AGG(rt.TagName, ', ') AS CombinedTags,
    COUNT(c.Id) AS TotalComments,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes
FROM 
    Posts p
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    RecursiveTags rt ON rt.Id IN (SELECT value FROM STRING_SPLIT(p.Tags, ','))
WHERE 
    p.PostTypeId = 1 -- Considering only questions
GROUP BY 
    p.Id, p.Title, p.CreationDate
HAVING 
    COUNT(c.Id) > 10 -- Only consider posts with more than 10 comments
ORDER BY 
    p.CreationDate DESC
LIMIT 50; -- Limit the output to 50 results
