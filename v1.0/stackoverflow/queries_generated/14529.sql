-- Performance Benchmarking Query
-- This query retrieves a summary of posts along with their related information, including user and vote counts

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    v.UpVoteCount,
    v.DownVoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
) v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for posts from the last year
ORDER BY 
    p.CreationDate DESC; -- Order by newest posts first
