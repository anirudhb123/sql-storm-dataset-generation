WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Start with Questions
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        p.CreationDate,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rp ON p.ParentId = rp.PostId
),
PostScores AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(v.Id) AS VoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upvotes
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    p.Title,
    u.DisplayName,
    upc.PostCount,
    ub.BadgeCount,
    ps.TotalBounty,
    ps.VoteCount,
    ps.CommentCount,
    rph.Level AS PostLevel,
    CASE 
        WHEN ps.TotalBounty > 100 THEN 'High Bounty'
        WHEN ps.TotalBounty <= 100 AND ps.TotalBounty > 0 THEN 'Medium Bounty'
        ELSE 'No Bounty' 
    END AS BountyCategory
FROM 
    Posts p
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserPostCounts upc ON u.Id = upc.UserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostScores ps ON p.Id = ps.PostId
LEFT JOIN 
    RecursivePostHierarchy rph ON p.Id = rph.PostId
WHERE 
    p.CreationDate < NOW() - INTERVAL '1 year' -- Only older posts
    AND (ps.VoteCount > 5 OR ps.CommentCount > 10) -- Filter condition
ORDER BY 
    ps.TotalBounty DESC,
    ps.VoteCount DESC
LIMIT 50;
