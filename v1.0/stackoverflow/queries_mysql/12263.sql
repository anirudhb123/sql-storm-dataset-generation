
WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName AS OwnerDisplayName
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY
),
PostStatistics AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(rp.Id) AS PostCount,
        AVG(rp.Score) AS AvgScore,
        SUM(rp.ViewCount) AS TotalViews
    FROM RecentPosts rp
    GROUP BY rp.OwnerDisplayName
),
TopUsers AS (
    SELECT 
        ps.OwnerDisplayName,
        ps.PostCount,
        ps.AvgScore,
        ps.TotalViews,
        @rank := @rank + 1 AS Rank
    FROM PostStatistics ps, (SELECT @rank := 0) r
    ORDER BY ps.TotalViews DESC
)
SELECT 
    Rank,
    OwnerDisplayName,
    PostCount,
    AvgScore,
    TotalViews
FROM TopUsers
WHERE Rank <= 10
ORDER BY Rank;
