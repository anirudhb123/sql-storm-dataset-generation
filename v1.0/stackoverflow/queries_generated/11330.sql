-- Performance benchmarking query to analyze posts, their scores, and associated user information
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    u.CreationDate AS UserCreationDate,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVotes,  -- Counting Upvotes
    SUM(v.VoteTypeId = 3) AS DownVotes  -- Counting Downvotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 100;  -- Limiting to top 100 posts for performance
