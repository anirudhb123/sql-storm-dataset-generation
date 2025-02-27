
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
),
UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViewCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.TotalViewCount,
    us.TotalScore,
    COUNT(DISTINCT rp.PostId) AS TopPostsCount,
    STRING_AGG(rp.Title, '; ') AS TopPostTitles,
    MAX(rp.Score) AS MaxScorePost,
    MIN(rp.Score) AS MinScorePost,
    AVG(rp.Score) AS AvgScorePost
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.PostId
WHERE 
    us.TotalPosts > 0
GROUP BY 
    us.DisplayName, us.TotalPosts, us.TotalViewCount, us.TotalScore
HAVING 
    SUM(CASE WHEN rp.Score IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY 
    us.TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
