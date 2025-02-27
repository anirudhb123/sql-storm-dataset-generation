-- Performance Benchmarking Query
-- This query will provide performance metrics by joining multiple tables to analyze post data, including user information, votes, and comments.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    ph.UserDisplayName AS LastEditorDisplayName,
    ph.CreationDate AS LastEditDate
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 4 -- Only interested in title edits
WHERE 
    p.PostTypeId = 1 -- Focusing on Questions
GROUP BY 
    p.Id, u.DisplayName, ph.UserDisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit to the most recent 100 posts for performance
