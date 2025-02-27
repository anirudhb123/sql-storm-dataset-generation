
WITH UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeCount
    FROM Badges
    GROUP BY UserId
),
PostAggregate AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM Posts
    WHERE CreationDate >= DATEADD(YEAR, -1, CAST('2024-10-01' AS DATE))
    GROUP BY OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COALESCE(ub.GoldCount, 0) AS GoldCount, 
        COALESCE(ub.SilverCount, 0) AS SilverCount,
        COALESCE(ub.BronzeCount, 0) AS BronzeCount,
        pa.TotalPosts,
        pa.TotalViews,
        pa.AverageScore,
        RANK() OVER (ORDER BY pa.TotalPosts DESC, pa.TotalViews DESC) AS UserRank
    FROM Users u
    LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN PostAggregate pa ON u.Id = pa.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    GoldCount,
    SilverCount,
    BronzeCount,
    TotalPosts,
    TotalViews,
    AverageScore,
    UserRank,
    CASE 
        WHEN UserRank <= 10 THEN 'Top User'
        WHEN UserRank BETWEEN 11 AND 50 THEN 'Active User'
        ELSE 'Inactive User'
    END AS UserCategory
FROM TopUsers
WHERE TotalPosts > 0
ORDER BY UserRank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
