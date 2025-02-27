-- Performance benchmarking SQL query for StackOverflow schema

-- This query retrieves a summary of posts, including user information, with respect to their associated votes and comments.
SELECT 
    p.Id AS PostID,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.Id AS UserID,
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount, -- Summing only Upvotes
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount -- Summing only Downvotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter to include only posts from the last year
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit the results to the latest 100 posts for benchmarking
