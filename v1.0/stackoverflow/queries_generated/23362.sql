WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
PostHistoryMetrics AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Close and reopen history
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)

SELECT 
    u.DisplayName,
    COALESCE(b.BadgeCount, 0) AS TotalBadges,
    (SELECT COUNT(DISTINCT p.Id) 
     FROM Posts p 
     WHERE p.OwnerUserId = u.Id AND p.Score > 5) AS HighScoringPosts,
    COUNT(DISTINCT pp.PostId) AS TotalPosts,
    SUM(CASE WHEN pp.Score > 10 THEN 1 ELSE 0 END) AS HighScorePosts,
    ARRAY_AGG(DISTINCT pt.Name) AS PostTypes,
    COALESCE(pm.ChangeCount, 0) AS HistoryChangeCount,
    COALESCE(pm.LastChangeDate, '1970-01-01') AS MostRecentChangeDate
FROM 
    Users u
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
LEFT JOIN 
    RankedPosts pp ON u.Id = pp.OwnerUserId
LEFT JOIN 
    PostHistoryMetrics pm ON pp.PostId = pm.PostId AND pm.PostHistoryTypeId IN (10, 11)
LEFT JOIN 
    PostTypes pt ON pp.PostTypeId = pt.Id
WHERE 
    u.Reputation >= 100 OR b.BadgeCount > 3
GROUP BY 
    u.DisplayName, b.BadgeCount, pm.ChangeCount, pm.LastChangeDate
HAVING 
    COUNT(DISTINCT pp.PostId) > 0
ORDER BY 
    u.DisplayName ASC, TotalBadges DESC, HighScoringPosts DESC
LIMIT 10
OFFSET 5;
