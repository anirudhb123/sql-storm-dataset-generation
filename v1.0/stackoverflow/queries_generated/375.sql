WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        AVG(v.BountyAmount) OVER (PARTITION BY p.Id) AS AvgBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS CloseCount,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    GROUP BY 
        p.Id
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(ps.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(ps.Id) > 5
    ORDER BY 
        TotalScore DESC
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.ScoreRank,
    cp.CloseCount,
    COALESCE(cp.CloseReasons, 'No close reasons') AS CloseReasons,
    au.DisplayName AS TopUser,
    au.TotalScore
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
JOIN 
    ActiveUsers au ON rp.ScoreRank = 1
WHERE 
    rp.AvgBounty IS NOT NULL
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 10;
