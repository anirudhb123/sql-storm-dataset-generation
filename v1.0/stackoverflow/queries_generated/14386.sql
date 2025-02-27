-- Performance benchmarking query for the StackOverflow schema
-- This query retrieves the most recent posts with their associated user information, vote counts, and comment counts
-- It will help to benchmark joining multiple tables and aggregate functions

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS AuthorDisplayName,
    u.Reputation AS AuthorReputation,
    COALESCE(votes.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(votes.DownVoteCount, 0) AS DownVoteCount,
    COALESCE(comments.CommentCount, 0) AS CommentCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
     FROM 
        Votes 
     GROUP BY 
        PostId) votes ON p.Id = votes.PostId
LEFT JOIN 
    (SELECT 
        PostId,
        COUNT(*) AS CommentCount
     FROM 
        Comments 
     GROUP BY 
        PostId) comments ON p.Id = comments.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'  -- Filter for posts from the last 30 days
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit for performance benchmarking
