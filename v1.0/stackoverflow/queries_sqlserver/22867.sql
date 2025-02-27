
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostOrder
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 month' 
        AND p.ViewCount > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties,
        COALESCE(SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswers,
        AVG(COALESCE(DATEDIFF(HOUR, u.LastAccessDate, CAST('2024-10-01 12:34:56' AS DATETIME)), 0)) AS AvgOfflineHours
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
        AND u.LastAccessDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '6 months'
    GROUP BY 
        u.Id, u.DisplayName
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.RankScore,
    us.DisplayName,
    us.BadgeCount,
    us.TotalBounties,
    us.AcceptedAnswers,
    us.AvgOfflineHours,
    COALESCE(cr.CloseReasons, '') AS CloseReasons
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON rp.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
WHERE 
    rp.RankScore <= 5
ORDER BY 
    rp.RankScore ASC, us.BadgeCount DESC;
