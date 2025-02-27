WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostVoteSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.OwnerUserId
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
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(pvs.TotalVotes, 0) AS TotalVotes,
    COALESCE(pvs.Upvotes, 0) AS Upvotes,
    COALESCE(pvs.Downvotes, 0) AS Downvotes,
    rp.Title AS LatestPostTitle,
    rp.CreationDate AS LatestPostDate
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostVoteSummary pvs ON u.Id = pvs.OwnerUserId
LEFT JOIN 
    RecentPosts rp ON u.Id = rp.OwnerUserId AND rp.rn = 1
WHERE 
    u.Reputation > 1000
ORDER BY 
    u.DisplayName;

SELECT 
    t.TagName,
    COUNT(DISTINCT p.Id) AS PostCount
FROM 
    Tags t
JOIN 
    Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
GROUP BY 
    t.TagName
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    PostCount DESC;

WITH ClosedPosts AS (
    SELECT 
        ph.PostId, 
        p.Title,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS ClosedCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    GROUP BY 
        ph.PostId, p.Title
    HAVING 
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) > 0
)
SELECT 
    cp.PostId,
    cp.Title,
    cp.ClosedCount
FROM 
    ClosedPosts cp
ORDER BY 
    cp.ClosedCount DESC;
