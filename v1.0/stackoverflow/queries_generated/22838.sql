WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        1 AS Level,
        p.Title,
        p.CreationDate,
        p.Score,
        CASE 
            WHEN p.ViewCount IS NULL THEN 0 
            ELSE p.ViewCount 
        END AS ViewCount
    FROM Posts p
    WHERE p.ParentId IS NULL  -- Start from root posts

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        Level + 1,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(p.ViewCount, 0) AS ViewCount
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.PostId
)

SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    SUM(CASE 
            WHEN p.ViewCount IS NULL THEN 0 
            ELSE p.ViewCount 
        END) AS TotalViews,
    COUNT(DISTINCT c.Id) AS TotalComments,
    MAX(v.BountyAmount) AS MaxBounty,
    AVG(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            WHEN v.VoteTypeId = 3 THEN -1 
            ELSE 0 
        END) AS AverageScore,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes,
    RANK() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank,
    COALESCE(MAX(SELECT COUNT(DISTINCT p2.Id)
                FROM Posts p2
                WHERE p2.AcceptedAnswerId = p.Id), 0) AS AcceptedAnswers

FROM Users u
LEFT JOIN Badges b ON u.Id = b.UserId
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id

WHERE 
    u.Reputation > 1000  -- Filter by reputation

GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 0  -- Users must have at least one post
ORDER BY 
    TotalViews DESC, 
    UserDisplayName;

-- BONUS: Include a check for solo creators of posts without comments
SELECT 
    p.Id AS PostId,
    p.Title,
    CASE 
        WHEN COUNT(c.Id) = 0 THEN 'No Comments'
        ELSE 'Has Comments'
    END AS CommentStatus
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
GROUP BY p.Id, p.Title
HAVING COUNT(c.Id) = 0 AND MIN(p.OwnerUserId) = p.OwnerUserId  -- Only solo creators without comments
ORDER BY p.CreationDate DESC;
