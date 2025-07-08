
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
        p.CreationDate BETWEEN ('2024-10-01 12:34:56'::timestamp - INTERVAL '1 year') AND ('2024-10-01 12:34:56'::timestamp)
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
        LISTAGG(b.Name, ', ') WITHIN GROUP (ORDER BY b.Name) AS BadgeNames,
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
        LISTAGG(DISTINCT pht.Name, ', ') WITHIN GROUP (ORDER BY pht.Name) AS PostHistoryTypes,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LastHistoryDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate > ('2024-10-01 12:34:56'::timestamp - INTERVAL '6 months')
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
        WHEN COALESCE(ph.LastHistoryDate, ('2024-10-01 12:34:56'::timestamp - INTERVAL '1 year')) < ('2024-10-01 12:34:56'::timestamp - INTERVAL '6 months') 
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
