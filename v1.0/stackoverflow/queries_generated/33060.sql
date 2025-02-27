WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= '2023-01-01'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation IS NOT NULL
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        ph.PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        us.TotalPosts,
        us.PositivePosts,
        us.NegativePosts,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        COALESCE(cp.FirstClosedDate, 'N/A') AS FirstClosedDate
    FROM 
        RankedPosts rp
    JOIN 
        UserStatistics us ON rp.PostId = us.UserId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.TotalPosts,
    pd.PositivePosts,
    pd.NegativePosts,
    pd.CloseCount,
    pd.FirstClosedDate,
    CASE 
        WHEN pd.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    PostDetails pd
WHERE 
    pd.RankByScore = 1  -- Fetch top post per user
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
