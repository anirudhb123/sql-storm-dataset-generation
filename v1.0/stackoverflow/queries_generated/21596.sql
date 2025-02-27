WITH RecursiveCTE AS (
    SELECT 
        Id, 
        PostTypeId, 
        Title, 
        OwnerUserId,
        ViewCount,
        CreationDate,
        CAST(Title AS varchar(500)) AS OriginalTitle,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Questions

    UNION ALL

    SELECT 
        p.Id, 
        p.PostTypeId, 
        p.Title, 
        p.OwnerUserId,
        p.ViewCount,
        p.CreationDate,
        CAST(r.Title || ' <- ' || p.Title AS varchar(500)),
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursiveCTE r ON r.Id = p.AcceptedAnswerId
    WHERE 
        p.PostTypeId = 2 -- Answers
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    MAX(r.VoteCount) AS HighestVoteCount,
    AVG(COALESCE(r.ViewCount, 0)) AS AvgViewCount,
    STRING_AGG(DISTINCT r.Tags, ', ') AS AssociatedTags,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    DENSE_RANK() OVER (PARTITION BY u.Id ORDER BY MAX(r.ViewCount) DESC) AS ViewRank
FROM 
    Users u
LEFT JOIN (
    SELECT 
        p.Id,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS VoteCount,
        p.ViewCount,
        p.Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
) r ON u.Id = r.OwnerUserId
LEFT JOIN 
    Badges b ON b.UserId = u.Id
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users) -- Users with above average reputation
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT r.Id) > 0 -- Only users with posts
ORDER BY 
    HighestVoteCount DESC, AvgViewCount DESC
LIMIT 50;

-- Note: This query includes a CTE for hierarchical post relationships, 
-- aggregates user data, incorporates NULL logic, and showcases advanced 
-- SQL features like window functions and string aggregation.
