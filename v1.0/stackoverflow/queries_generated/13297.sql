-- Performance benchmarking query for Stack Overflow schema

-- This query retrieves performance metrics on posts, user activity, and closed posts.
SELECT 
    p.Id AS PostID,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    p.LastActivityDate AS PostLastActivityDate,
    p.ViewCount AS PostViewCount,
    p.Score AS PostScore,
    p.AnswerCount AS NumberOfAnswers,
    p.CommentCount AS NumberOfComments,
    p.ClosedDate AS PostClosedDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id 
LEFT JOIN 
    Comments c ON p.Id = c.PostId 
LEFT JOIN 
    Votes v ON p.Id = v.PostId 
LEFT JOIN 
    Badges b ON u.Id = b.UserId 
WHERE 
    p.CreationDate >= '2023-01-01' -- Filter for posts created in 2023
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.Score DESC -- Sorting by post score for performance
LIMIT 100; -- Limit to top 100 posts for benchmarking
