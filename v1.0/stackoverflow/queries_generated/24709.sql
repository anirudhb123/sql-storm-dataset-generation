WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(pt.Name, 'Unknown') AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), 
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.PostType,
        rp.Score,
        rp.ViewCount,
        CASE 
            WHEN rp.Score > 100 THEN 'High Scorer'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium Scorer'
            ELSE 'Low Scorer'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalScore,
    ps.ScoreCategory,
    COUNT(c.Id) AS CommentCount,
    MAX(ph.CreationDate) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS LastClosedDate
FROM 
    UserStats us
LEFT JOIN 
    Comments c ON us.UserId = c.UserId
LEFT JOIN 
    PostStats ps ON us.TotalPosts > 0
LEFT JOIN 
    PostHistory ph ON us.TotalPosts > 0 AND ph.PostId IN (SELECT PostId FROM PostStats)
GROUP BY 
    us.UserId, us.DisplayName, ps.ScoreCategory
ORDER BY 
    us.TotalScore DESC NULLS LAST, us.TotalPosts DESC, us.DisplayName;
