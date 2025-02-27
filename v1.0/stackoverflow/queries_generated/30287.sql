WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        AVG(p.Score) AS AvgPostScore,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(CONVERT(varchar, ph.CreationDate, 120), ', ') AS HistoryDates
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATEADD(month, -6, GETDATE())
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)

SELECT 
    ua.UserId, 
    ua.DisplayName,
    ua.Reputation,
    ua.TotalPosts,
    ua.PositivePosts,
    ROUND(ua.AvgPostScore, 2) AS AvgPostScore,
    phs.PostId,
    MAX(phs.HistoryCount) AS MaxHistoryCount,
    STRING_AGG(phs.HistoryDates, '; ') AS AllHistoryDates
FROM 
    UserActivity ua
LEFT JOIN 
    PostHistorySummary phs ON ua.TotalPosts > 0 AND phs.PostId IN (SELECT PostId FROM RankedPosts WHERE PostRank = 1)
GROUP BY 
    ua.UserId, ua.DisplayName, ua.Reputation, phs.PostId
HAVING 
    ua.Reputation > 100 AND 
    (MAX(phs.HistoryCount) IS NULL OR MAX(phs.HistoryCount) > 5)
ORDER BY 
    ua.Reputation DESC, ua.TotalPosts DESC;
