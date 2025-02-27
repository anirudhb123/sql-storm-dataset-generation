WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount,
        RANK() OVER (ORDER BY SUM(p.Score) DESC) AS UserScoreRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id
),
CloseReasonCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS CloseCount,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    GROUP BY 
        p.Id
)
SELECT 
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.CommentCount,
    tu.DisplayName,
    tu.TotalScore,
    tu.AvgViewCount,
    c.CloseCount,
    COALESCE(c.CloseReasons, 'No close reasons') AS CloseReasons
FROM 
    RankedPosts r
JOIN 
    TopUsers tu ON r.UserPostRank = 1 AND tu.UserId = r.OwnerUserId
LEFT JOIN 
    CloseReasonCounts c ON r.PostId = c.PostId
WHERE 
    r.ViewCount > 50
ORDER BY 
    r.Score DESC, r.ViewCount DESC
LIMIT 100;
