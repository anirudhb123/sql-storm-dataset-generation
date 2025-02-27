
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT crt.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS UNSIGNED) = crt.Id 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY ph.PostId
)

SELECT
    up.DisplayName AS UserName,
    up.Reputation AS UserReputation,
    rp.Title AS PostTitle,
    rp.ViewCount AS PostViewCount,
    rp.Score AS PostScore,
    ups.TotalPosts AS UserTotalPosts,
    ups.TotalBadgeClass AS UserTotalBadgeClass,
    cp.CloseReasons AS ClosedReasons
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
JOIN 
    UserStats ups ON up.Id = ups.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.ScoreRank = 1
    AND ups.TotalPosts > 5
    AND (rp.ViewCount > (SELECT AVG(ViewCount) FROM Posts WHERE CreationDate >= NOW() - INTERVAL 1 YEAR))
ORDER BY 
    rp.Score DESC, up.Reputation DESC;
