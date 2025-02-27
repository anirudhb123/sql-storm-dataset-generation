-- Performance benchmarking query to analyze posts and their associated details, 
-- such as user reputation, post scores, and number of comments.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score AS PostScore,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.Reputation AS UserReputation,
    u.DisplayName AS UserDisplayName,
    u.Location,
    COUNT(c.Id) AS TotalComments,
    p.Tags,
    pt.Name AS PostTypeName,
    p.LastActivityDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= '2023-01-01' -- Filter for posts created this year
GROUP BY 
    p.Id, u.Reputation, u.DisplayName, u.Location, pt.Name
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 100; -- Limit results for benchmarking
