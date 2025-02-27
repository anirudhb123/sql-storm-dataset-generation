WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS ClosedDate
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Closed posts
)
SELECT 
    up.DisplayName,
    rp.Title,
    rp.CreationDate,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(cp.ClosedDate, 'Not Closed') AS LastClosedDate
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
WHERE 
    rp.rn = 1 -- Get the highest score question per user
ORDER BY 
    rp.Score DESC,
    up.Reputation DESC
LIMIT 10;

WITH RecursiveTagCounts AS (
    SELECT 
        t.Id,
        t.TagName,
        t.Count
    FROM 
        Tags t
    WHERE 
        t.Count > 0
    UNION ALL
    SELECT 
        t.Id,
        t.TagName,
        t.Count * rc.Count 
    FROM 
        Tags t
    JOIN 
        RecursiveTagCounts rc ON rc.Id = t.Id
    WHERE 
        t.Count > 0
)
SELECT 
    tag.TagName,
    SUM(tag.Count) AS TotalCount
FROM 
    RecursiveTagCounts tag
GROUP BY 
    tag.TagName
HAVING 
    SUM(tag.Count) > 100
ORDER BY 
    TotalCount DESC;
