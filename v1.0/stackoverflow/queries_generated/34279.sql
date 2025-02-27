WITH RecursivePostHierarchy AS (
    -- Recursive CTE to build a hierarchy of answers for questions
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        r.Level + 1 AS Level
    FROM 
        Posts a
    INNER JOIN 
        Posts q ON a.ParentId = q.Id  -- Join to find answers to questions
    INNER JOIN 
        RecursivePostHierarchy r ON q.Id = r.PostId  
)

SELECT 
    u.DisplayName AS UserName,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
    COALESCE(MAX(b.Date), 'Never Awarded') AS LastAwardDate,
    RANK() OVER (ORDER BY COALESCE(SUM(v.BountyAmount), 0) DESC) AS UserRank

FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- Bounty start/close only
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1  -- Gold badges only (for awards)

WHERE 
    u.Reputation > 1000 AND  -- Only users with reputation over 1000
    u.CreationDate < NOW() - INTERVAL '2 years'  -- Users who joined more than 2 years ago

GROUP BY 
    u.DisplayName

HAVING 
    COUNT(DISTINCT p.Id) > 10  -- Users with more than 10 posts

ORDER BY 
    UserRank
LIMIT 10; -- Top 10 users
