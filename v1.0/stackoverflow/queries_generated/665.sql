WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS score_rank
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        us.Reputation,
        us.PostCount,
        us.TotalViews,
        us.PositiveScoreCount,
        cr.CloseReasonNames
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    LEFT JOIN 
        CloseReasons cr ON rp.Id = cr.PostId
)
SELECT 
    tp.Title,
    tp.Score,
    tp.Reputation,
    tp.TotalViews,
    tp.PostCount,
    tp.PositiveScoreCount,
    COALESCE(tp.CloseReasonNames, 'No Close Reasons') AS CloseReasons
FROM 
    TopPosts tp
WHERE 
    tp.score_rank = 1 
ORDER BY 
    tp.Score DESC
FETCH FIRST 10 ROWS ONLY;
