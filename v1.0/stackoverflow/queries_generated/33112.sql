WITH RecursiveUserHierarchy AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation, 
        CreationDate, 
        0 AS Level
    FROM 
        Users
    WHERE 
        Id = (SELECT MIN(Id) FROM Users)  -- Start from the user with the lowest ID

    UNION ALL

    SELECT 
        u.Id, 
        u.DisplayName, 
        u.Reputation, 
        u.CreationDate, 
        Level + 1
    FROM 
        Users u
    INNER JOIN 
        RecursiveUserHierarchy uh ON u.Id = uh.Id + 1  -- Hierarchy joins on user ID increment
)

SELECT 
    p.Title, 
    p.CreationDate, 
    p.Score, 
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT b.Id) AS BadgesReceived,
    uh.DisplayName AS OwnerDisplayName,
    uh.Reputation AS OwnerReputation,
    (SELECT COUNT(*) FROM Comments WHERE PostId = p.Id) AS TotalComments
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
LEFT JOIN 
    RecursiveUserHierarchy uh ON p.OwnerUserId = uh.Id
WHERE 
    p.CreationDate > NOW() - INTERVAL '1 year'  -- Only posts created in the last year
GROUP BY 
    p.Title, p.CreationDate, p.Score, uh.DisplayName, uh.Reputation
HAVING 
    COUNT(DISTINCT c.Id) > 5  -- Only include posts with more than 5 comments
ORDER BY 
    (Upvotes - Downvotes) DESC, -- Order by net votes
    p.CreationDate DESC  -- Then by date
LIMIT 10;  -- Return the top 10 posts
