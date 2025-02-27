-- Performance benchmarking query to analyze posts and their associated users and tags
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    t.TagName,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    LATERAL (SELECT UNNEST(REGEXP_SPLIT_TO_ARRAY(p.Tags, '><')) AS TagName) AS t ON TRUE
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- filter for posts created in the last year
GROUP BY 
    p.Id, u.DisplayName, t.TagName
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- limit results for performance
