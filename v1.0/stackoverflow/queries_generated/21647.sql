WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE((
            SELECT AVG(CAST(Body AS VARCHAR)) 
            FROM Posts 
            WHERE OwnerUserId = p.OwnerUserId
        ), 'N/A') AS AvgPostLength
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= current_date - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostClosureReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons,
        COUNT(DISTINCT ph.UserId) AS TotalClosureVotes
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment = cr.Id::text
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.Rank,
    r.AvgPostLength,
    u.TotalPosts,
    u.TotalBounties,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    COALESCE(pcr.CloseReasons, 'No Closures') AS CloseReasons,
    COALESCE(pcr.TotalClosureVotes, 0) AS ClosureVotes
FROM 
    RankedPosts r
JOIN 
    Users u ON r.Rank = 1 AND u.Id = r.OwnerUserId
LEFT JOIN 
    PostClosureReasons pcr ON r.PostId = pcr.PostId
WHERE 
    r A.Days BETWEEN 7 AND 90
ORDER BY 
    r.Score DESC, 
    u.TotalPosts DESC;
