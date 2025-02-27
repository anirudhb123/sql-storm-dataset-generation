WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(DISTINCT pht.Name) AS HistoryTypes,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        ph.PostId
),
UserReputationStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalBadges,
    up.TotalPosts,
    up.TotalComments,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rph.HistoryCount,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No Views'
        ELSE 'Has Views'
    END AS ViewStatus,
    CASE 
        WHEN rp.PostRank IS NULL THEN 'No Posts'
        ELSE 'Ranked Post'
    END AS PostRanking,
    STRING_AGG(rph.HistoryTypes::TEXT, ', ') AS HistoryTypeNames
FROM 
    UserReputationStats up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    RecentPostHistory rph ON rph.PostId = rp.PostId
WHERE 
    up.TotalBadges > 0 OR up.TotalPosts > 0
ORDER BY 
    up.TotalBadges DESC, 
    up.TotalPosts DESC, 
    rp.Score DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
