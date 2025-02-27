
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(ut.Reputation, 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users ut ON p.OwnerUserId = ut.Id
    WHERE 
        p.CreationDate BETWEEN CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR AND CAST('2024-10-01 12:34:56' AS DATETIME)
        AND p.PostTypeId = 1 
),
PostStats AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(rp.PostId) AS NumberOfPosts,
        AVG(rp.Score) AS AvgScore,
        MAX(rp.ViewCount) AS MaxViews
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserReputation > 100 
    GROUP BY 
        rp.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate AS HistoryDate,
        GROUP_CONCAT(DISTINCT pht.Name SEPARATOR ', ') AS PostHistoryTypes,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate > CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 6 MONTH
    GROUP BY 
        ph.PostId, ph.UserId, ph.CreationDate
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(ps.NumberOfPosts, 0) AS TotalPosts,
    COALESCE(ps.AvgScore, 0) AS AverageScore,
    COALESCE(ps.MaxViews, 0) AS MostViewedPost,
    COALESCE(ub.BadgeNames, 'No Badges') AS BadgeList,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ph.PostHistoryTypes, 'No History') AS RecentPostHistory,
    CASE 
        WHEN COALESCE(ph.LastHistoryDate, CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR) < CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 6 MONTH 
        THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus
FROM 
    Users u
LEFT JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryDetails ph ON u.Id = ph.UserId
WHERE 
    u.Reputation > 50
ORDER BY 
    u.Reputation DESC;
