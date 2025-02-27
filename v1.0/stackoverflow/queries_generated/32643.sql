WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
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
RecentHighlyVotedPosts AS (
    SELECT 
        p.Id,
        p.Score,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY 
        p.Id, p.Score
    HAVING 
        COUNT(v.Id) > 10 AND p.Score > 5
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastModified
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    u.DisplayName AS Author,
    p.Title,
    bp.BadgeCount,
    COALESCE(rp.rn, 0) AS RecentPostRank,
    r.VoteCount,
    ph.HistoryCount,
    ph.LastModified
FROM 
    Users u
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
JOIN 
    UserBadges bp ON u.Id = bp.UserId
JOIN 
    RecentHighlyVotedPosts r ON rp.PostId = r.Id
JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId
WHERE 
    bp.BadgeCount > 0
ORDER BY 
    bp.BadgeCount DESC, 
    r.VoteCount DESC, 
    rp.CreationDate DESC
LIMIT 100;
