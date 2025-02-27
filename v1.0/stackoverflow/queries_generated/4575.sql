WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > '2023-01-01'
        AND p.Score > 0
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
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
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(CASE WHEN ph.CreationDate > '2023-01-01' THEN 1 ELSE 0 END) AS ClosedThisYear
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Close and Reopen
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    COALESCE(up.PostId, rp.PostId) AS TopPostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(up.TotalBadges, 0) AS UserBadges,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    cp.CloseCount,
    cp.ClosedThisYear,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Users u
LEFT JOIN 
    UserBadges up ON u.Id = up.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    ClosedPostHistory cp ON rp.PostId = cp.PostId
LEFT JOIN 
    LATERAL (
        SELECT 
            STRING_AGG(DISTINCT TRIM(UNNEST(string_to_array(p.Tags, '><'))), ', ') AS TagName
        FROM 
            Posts p
        WHERE 
            p.Id = rp.PostId
    ) t ON TRUE
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, rp.PostId, rp.Title, rp.CreationDate, up.TotalBadges, up.GoldBadges, up.SilverBadges, up.BronzeBadges, cp.CloseCount, cp.ClosedThisYear
ORDER BY 
    up.TotalBadges DESC, rp.ViewCount DESC;
