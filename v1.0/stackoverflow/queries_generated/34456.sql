WITH RECURSIVE PostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  -- Start with root posts (i.e., top-level questions)
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
),
LatestVotes AS (
    SELECT 
        PostId,
        VoteTypeId,
        ROW_NUMBER() OVER (PARTITION BY PostId ORDER BY CreationDate DESC) AS rn
    FROM 
        Votes
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(v.BountyAmount) > 0
    ORDER BY 
        TotalBounties DESC
    LIMIT 10
)
SELECT 
    ph.Id AS PostId,
    ph.Title,
    COALESCE(uv.TotalBounties, 0) AS UserTotalBounties,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT bc.Id) AS BadgeCount,
    COUNT(DISTINCT lv.VoteTypeId) AS VoteCount,
    MAX(lv.CreationDate) AS LastVoteDate
FROM 
    PostHierarchy ph
LEFT JOIN 
    LatestVotes lv ON lv.PostId = ph.Id AND lv.rn = 1
LEFT JOIN 
    Comments c ON c.PostId = ph.Id
LEFT JOIN 
    Badges bc ON bc.UserId IN (SELECT u.Id FROM Users u WHERE u.Reputation > 1000) -- Users with reputation over 1000
LEFT JOIN 
    TopUsers uv ON uv.Id = ph.Id
WHERE 
    ph.Level = 0  -- Only top-level posts
GROUP BY 
    ph.Id, ph.Title, uv.TotalBounties
HAVING 
    COUNT(DISTINCT c.Id) > 5  -- Posts with more than 5 comments
ORDER BY 
    UserTotalBounties DESC, LastVoteDate DESC;
