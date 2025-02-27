-- Performance benchmarking query to retrieve posts along with user details, vote counts, and tags
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS VoteCount,
    STRING_AGG(t.TagName, ', ') AS Tags,
    COALESCE(p.AnswerCount, 0) AS AnswerCount,
    COALESCE(p.CommentCount, 0) AS CommentCount,
    COALESCE(p.ViewCount, 0) AS ViewCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Tags t ON p.Tags LIKE '%' || t.TagName || '%'  -- Assuming Tags field contains tag names separated by a delimiter
WHERE 
    p.PostTypeId = 1  -- Filtering for questions only
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit to the latest 100 posts for benchmarking
