WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.Score > 0 -- Only Questions with a positive score
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.CreationDate > NOW() - INTERVAL '30 days' THEN 1 ELSE 0 END) AS PostsLast30Days,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    ups.TotalPosts,
    ups.TotalViews,
    ups.PostsLast30Days,
    ups.AvgScore,
    COALESCE(cph.CloseCount, 0) AS CloseCount,
    cph.LastClosedDate,
    array_agg(DISTINCT pp.Title) AS RecentPosts
FROM 
    Users u
JOIN 
    UserPostStats ups ON u.Id = ups.UserId
LEFT JOIN 
    ClosedPostHistory cph ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = cph.PostId)
LEFT JOIN 
    RankedPosts pp ON pp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
WHERE 
    ups.TotalPosts > 0 
    AND ups.AvgScore < (SELECT AVG(AvgScore) FROM UserPostStats) 
    AND (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id AND b.Class = 1) > 0 -- At least one Gold badge
GROUP BY 
    u.Id, ups.TotalPosts, ups.TotalViews, ups.PostsLast30Days, ups.AvgScore, cph.CloseCount, cph.LastClosedDate
ORDER BY 
    ups.TotalViews DESC, ups.AvgScore ASC
LIMIT 10;
