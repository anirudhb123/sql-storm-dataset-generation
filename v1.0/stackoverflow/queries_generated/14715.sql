-- Performance benchmarking query for the StackOverflow schema

-- This query checks the performance of retrieving post details along with user information
-- and the count of comments and votes associated with each post.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    COUNT(c.Id) AS TotalComments,
    COUNT(v.Id) AS TotalVotes
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2022-01-01' -- Filter posts created from the beginning of 2022
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit to the latest 100 posts
