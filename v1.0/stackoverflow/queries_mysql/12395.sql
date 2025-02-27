
WITH PostAggregates AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(IFNULL(p.Score, 0)) AS TotalScore,
        AVG(IFNULL(p.Score, 0)) AS AvgScore,
        COUNT(c.Id) AS CommentCount,
        MAX(p.CreationDate) AS LatestPostDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
    GROUP BY 
        p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        IFNULL(pa.PostCount, 0) AS PostCount,
        IFNULL(pa.TotalViews, 0) AS TotalViews,
        IFNULL(pa.TotalScore, 0) AS TotalScore,
        IFNULL(pa.AvgScore, 0) AS AvgScore,
        IFNULL(pa.CommentCount, 0) AS CommentCount,
        pa.LatestPostDate
    FROM 
        Users u
    LEFT JOIN 
        PostAggregates pa ON u.Id = pa.OwnerUserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.TotalViews,
    us.TotalScore,
    us.AvgScore,
    us.CommentCount,
    us.LatestPostDate
FROM 
    UserStats us
ORDER BY 
    us.Reputation DESC, us.PostCount DESC
LIMIT 100;
