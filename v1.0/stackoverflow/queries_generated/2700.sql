WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.ViewCount, 
        p.AnswerCount, 
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes, 
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
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
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        MAX(ph.CreationDate) as LastClosedDate,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    up.OwnerDisplayName AS User, 
    rp.Title, 
    rp.ViewCount, 
    rp.Score, 
    rp.AnswerCount, 
    ub.GoldBadges, 
    ub.SilverBadges, 
    ub.BronzeBadges,
    cp.LastClosedDate,
    cp.CloseCount,
    CASE 
        WHEN cp.CloseCount > 0 THEN 'Closed' 
        ELSE 'Open' 
    END AS Status
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 50;
