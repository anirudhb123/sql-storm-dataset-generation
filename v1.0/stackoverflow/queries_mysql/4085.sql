
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.Score, 
        p.CreationDate, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
), 
UserPostStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(IFNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(IF(p.Score > 0, p.Score, 0)) AS PositiveScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.PostCount,
    up.TotalViews,
    up.PositiveScore,
    IFNULL(cp.CloseCount, 0) AS CloseCount,
    GROUP_CONCAT(rp.Title) AS TopPosts
FROM 
    UserPostStats up
LEFT JOIN 
    ClosedPosts cp ON up.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId)
LEFT JOIN 
    RankedPosts rp ON up.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId AND Rank <= 3)
GROUP BY 
    up.UserId, up.DisplayName, up.PostCount, up.TotalViews, up.PositiveScore, cp.CloseCount
HAVING 
    up.PostCount > 5
ORDER BY 
    up.TotalViews DESC;
