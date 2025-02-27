WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level,
        p.CreationDate
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1,
        p.CreationDate
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
)
SELECT 
    us.DisplayName,
    us.PostCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.UpVotes,
    us.DownVotes,
    COALESCE(pH.Title, 'No Parent') AS ParentPostTitle,
    rp.Title AS LatestPostTitle,
    pH.Level AS PostLevel,
    pH.CreationDate AS ParentCreationDate
FROM 
    UserStats us
LEFT JOIN 
    PostHierarchy pH ON pH.PostId IN (SELECT DISTINCT ParentId FROM Posts WHERE ParentId IS NOT NULL)
LEFT JOIN 
    RecentPosts rp ON us.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    us.PostCount > 0
ORDER BY 
    us.PostCount DESC, 
    us.GoldBadges DESC, 
    us.UpVotes DESC;

