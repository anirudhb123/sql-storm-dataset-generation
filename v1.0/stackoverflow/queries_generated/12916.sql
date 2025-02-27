-- Performance Benchmarking Query

-- This query will benchmark the retrieval of posts along with their respective user details, tags, and vote counts.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT v.Id) AS VoteCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
    (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = p.Id) AS LinkCount,
    (SELECT STRING_AGG(t.TagName, ', ') FROM Tags t WHERE t.Id IN (
        SELECT UNNEST(STRING_TO_ARRAY(p.Tags, '><'))::int
    )) AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- Filter for the last year
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit the result set to the most recent 100 posts
