-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        SUM(CASE WHEN P.CreationDate >= NOW() - INTERVAL '1 month' THEN 1 ELSE 0 END) AS RecentPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TotalScore,
        TotalViews,
        RecentPosts,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserStats
)
SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.Questions,
    U.Answers,
    U.TotalScore,
    U.TotalViews,
    U.RecentPosts
FROM 
    TopUsers U
WHERE 
    U.ScoreRank <= 10 -- Top 10 users
ORDER BY 
    U.TotalScore DESC;
