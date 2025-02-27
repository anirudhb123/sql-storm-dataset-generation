WITH RecursiveUserStats AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.UpVotes,
        u.DownVotes,
        u.ViewCount,
        1 AS Level
    FROM Users u
    WHERE u.Reputation > 1000
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.UpVotes,
        u.DownVotes,
        u.ViewCount,
        Level + 1
    FROM Users u
    INNER JOIN RecursiveUserStats rus ON rus.Id = u.Id  -- Assuming some hierarchical relationship based on Id
    WHERE u.Reputation > 1000 AND Level < 5
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM Badges b
    GROUP BY b.UserId
),
PostsSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(p.Score) AS AvgScore,
        COUNT(DISTINCT p.Tags) AS UniqueTags
    FROM Posts p
    GROUP BY p.OwnerUserId
),
PostsHistorySummary AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit actions only
    GROUP BY ph.UserId
)
SELECT 
    u.Id,
    u.DisplayName,
    u.Reputation,
    COALESCE(ubs.GoldCount, 0) AS GoldBadges,
    COALESCE(ubs.SilverCount, 0) AS SilverBadges,
    COALESCE(ubs.BronzeCount, 0) AS BronzeBadges,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    COALESCE(ps.TotalViews, 0) AS TotalViews,
    COALESCE(ps.AvgScore, 0) AS AvgScore,
    COALESCE(ps.UniqueTags, 0) AS UniqueTags,
    COALESCE(phs.EditCount, 0) AS TotalEdits,
    COALESCE(phs.LastEditDate, '1970-01-01') AS LastEditDate
FROM Users u
LEFT JOIN UserBadges ubs ON u.Id = ubs.UserId
LEFT JOIN PostsSummary ps ON u.Id = ps.OwnerUserId
LEFT JOIN PostsHistorySummary phs ON u.Id = phs.UserId
WHERE u.Reputation > 1000
ORDER BY u.Reputation DESC;

