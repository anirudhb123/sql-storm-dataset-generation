-- Performance Benchmarking Query to analyze post creation and user reputation metrics

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.Id AS UserId,
    u.DisplayName AS UserName,
    u.Reputation,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    COUNT(v.Id) AS TotalVotes,
    AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AvgUpvotes, -- Count of UpMods (upvotes)
    AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS AvgDownvotes -- Count of DownMods (downvotes)
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= DATEADD(month, -6, GETDATE()) -- Filter for posts created in the last 6 months
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.Id, u.DisplayName, u.Reputation, p.ViewCount, p.Score, p.AnswerCount, p.CommentCount
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit the results to the top 100 most recent posts
