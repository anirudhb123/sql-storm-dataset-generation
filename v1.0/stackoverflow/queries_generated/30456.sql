WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Starting from root posts

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),

UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    u.DisplayName AS PostOwner,
    ph.Title AS PostTitle,
    ps.ViewCount,
    ps.Score,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ph.Level AS Depth,
    array_agg(DISTINCT pt.Name) AS PostTypes,
    NULLIF(ps.UpVotes - ps.DownVotes, 0) AS NetVotes
FROM 
    PostHierarchy ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserBadgeCounts ub ON u.Id = ub.UserId
JOIN 
    PostStats ps ON p.Id = ps.PostId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    ph.Level <= 3  -- Limiting depth for performance
GROUP BY 
    u.DisplayName, ph.Title, ps.ViewCount, ps.Score, ub.BadgeCount, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges, ph.Level
ORDER BY 
    ps.ViewCount DESC, NetVotes DESC
LIMIT 100;
