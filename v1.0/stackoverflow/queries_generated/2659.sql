WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.LastAccessDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name) AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    au.UserId,
    au.DisplayName,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    COALESCE(cp.CloseReasons, 'No close reasons') AS CloseReasons,
    CASE 
        WHEN rp.ViewRank <= 5 THEN 'Top Viewed'
        ELSE 'Other'
    END AS PostCategory,
    STRING_AGG(DISTINCT b.Name) AS BadgeNames
FROM 
    ActiveUsers au
JOIN 
    RankedPosts rp ON au.UserId = rp.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
LEFT JOIN 
    Badges b ON au.UserId = b.UserId 
WHERE 
    b.Class = 1 OR b.Class = 2 -- Only gold or silver badges
GROUP BY 
    au.UserId, au.DisplayName, rp.Id, rp.Title, rp.ViewCount, rp.Score, cp.CloseCount, cp.CloseReasons, rp.ViewRank
ORDER BY 
    au.Reputation DESC, rp.Score DESC;
