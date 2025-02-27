WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.Score DESC) AS RankInYear
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '5 years'
),
HighestRankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        p.Score > 0
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
PostCloseDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate AS CloseDate,
        cr.Name AS CloseReason
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rpu.UserId,
    rpu.DisplayName,
    COALESCE(pd.CloseDate, 'No Closure') AS ClosureDate,
    COALESCE(pd.CloseReason, 'N/A') AS ClosureReason,
    rpu.TotalScore,
    rpu.AverageScore
FROM 
    RankedPosts rp
LEFT JOIN 
    HighestRankedUsers rpu ON rpu.PostCount = (SELECT MAX(PostCount) FROM HighestRankedUsers)
LEFT JOIN 
    PostCloseDetails pd ON pd.PostId = rp.PostId
WHERE 
    rp.RankInYear <= 10
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
