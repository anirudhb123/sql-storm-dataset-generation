WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LastCloseDate,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    rs.PostId, 
    rs.Title,
    rs.ViewCount,
    us.DisplayName AS UserDisplayName,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    cp.LastCloseDate,
    cp.CloseCount
FROM 
    RankedPosts rs
JOIN 
    Users u ON rs.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
LEFT JOIN 
    UserStatistics us ON u.Id = us.UserId
LEFT JOIN 
    ClosedPosts cp ON rs.PostId = cp.PostId
WHERE 
    rs.Rank <= 5
ORDER BY 
    rs.ViewCount DESC NULLS LAST
LIMIT 50;
