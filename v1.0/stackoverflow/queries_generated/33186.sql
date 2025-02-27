WITH Recursive PostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL -- Top-level posts (Questions)

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostCTE cte ON p.ParentId = cte.Id -- Join to find Answers to Questions
)

SELECT 
    u.DisplayName AS Author,
    p.Title AS QuestionTitle,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    COALESCE(MAX(b.Class), 0) AS HighestBadge,
    p.Score,
    DATEDIFF(MINUTE, p.CreationDate, GETDATE()) AS MinutesSinceCreation,
    ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS RowNum
FROM 
    PostCTE p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId 
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Only Questions
    AND u.Reputation > 1000 -- Only users with high reputation
GROUP BY 
    u.DisplayName, p.Title, p.Score
HAVING 
    COUNT(c.Id) > 0 -- Only include questions with comments
ORDER BY 
    TotalUpVotes DESC, MinutesSinceCreation ASC; -- Order by votes and time
