WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' 
        AND p.ViewCount > 100
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
CloseReasonStats AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS CloseCount,
        MIN(ph.CreationDate) AS FirstCloseDate,
        MAX(ph.CreationDate) AS LastCloseDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS INTEGER)
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Considering closed and reopened posts
    GROUP BY 
        ph.UserId
)
SELECT 
    u.DisplayName,
    us.TotalPosts,
    us.PositivePosts,
    us.NegativePosts,
    us.AvgScore,
    rsp.PostId,
    rsp.Title,
    rsp.Score,
    COALESCE(crs.CloseCount, 0) AS UserCloseCount,
    crs.CloseReasons,
    rsp.CreationDate
FROM 
    UserStats us
INNER JOIN 
    Users u ON u.Id = us.UserId
LEFT JOIN 
    RankedPosts rsp ON rsp.PostId IN (
        SELECT PostId FROM Posts WHERE OwnerUserId = u.Id
    )
LEFT JOIN 
    CloseReasonStats crs ON crs.UserId = u.Id
WHERE 
    us.TotalPosts > 10
ORDER BY 
    us.AvgScore DESC,
    rsp.CreationDate DESC;
