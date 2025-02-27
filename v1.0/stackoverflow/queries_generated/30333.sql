WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
UserStats AS (
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
        u.Id
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId AS ClosedByUserId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ClosureRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),
FinalResult AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        COALESCE(SUM(rp.Score), 0) AS TotalScore,
        COALESCE(SUM(rp.ViewCount), 0) AS TotalViewCount,
        COALESCE(MAX(rp.CreationDate), '1900-01-01') AS LastPostDate,
        us.BadgeCount,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        COALESCE(COUNT(cph.PostId), 0) AS ClosedPostCount
    FROM 
        UserStats us
    JOIN 
        Users up ON us.UserId = up.Id
    LEFT JOIN 
        RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.PostRank = 1
    LEFT JOIN 
        ClosedPostHistory cph ON up.Id = cph.ClosedByUserId
    GROUP BY 
        up.UserId, up.DisplayName, us.BadgeCount, us.GoldBadges, us.SilverBadges, us.BronzeBadges
)
SELECT 
    *,
    CONCAT(DisplayName, ' (Last Post: ', LastPostDate, ')') AS UserSummary
FROM 
    FinalResult
ORDER BY 
    TotalScore DESC, ClosedPostCount DESC, LastPostDate DESC
LIMIT 10;
