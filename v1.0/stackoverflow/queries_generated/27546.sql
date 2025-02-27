WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostAggregation AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        MAX(p.CreationDate) AS LatestPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
BadgeTrends AS (
    SELECT 
        b.UserId,
        DATE(b.Date) AS BadgeDate,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Badges b
    GROUP BY b.UserId, DATE(b.Date)
),
PostHistoryAnalysis AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)  -- Obtain edits of title, body, and tags
    GROUP BY ph.UserId, ph.PostId
),
FinalStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.CommentCount,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        pa.TotalPosts,
        pa.TotalScore,
        pa.TotalViews,
        pa.LatestPostDate,
        COALESCE(bad.BadgeCount, 0) AS TotalBadges,
        COALESCE(bad.GoldCount, 0) AS TotalGoldBadges,
        COALESCE(bad.SilverCount, 0) AS TotalSilverBadges,
        COALESCE(bad.BronzeCount, 0) AS TotalBronzeBadges,
        COALESCE(ph.EditCount, 0) AS TotalEdits,
        COALESCE(ph.LastEdited, '1900-01-01') AS LastEditedPostDate
    FROM UserStats us
    LEFT JOIN PostAggregation pa ON us.UserId = pa.OwnerUserId
    LEFT JOIN BadgeTrends bad ON us.UserId = bad.UserId
    LEFT JOIN PostHistoryAnalysis ph ON us.UserId = ph.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    CommentCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalPosts,
    TotalScore,
    TotalViews,
    LatestPostDate,
    TotalBadges,
    TotalGoldBadges,
    TotalSilverBadges,
    TotalBronzeBadges,
    TotalEdits,
    LastEditedPostDate
FROM FinalStats
ORDER BY Reputation DESC, PostCount DESC;
