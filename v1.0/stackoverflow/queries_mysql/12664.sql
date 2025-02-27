
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(B.Id, 0)) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalViews,
        TotalScore,
        TotalBadges,
        @rank := IF(@prev_score = TotalScore, @rank, @rank + 1) AS ScoreRank,
        @prev_score := TotalScore
    FROM 
        UserStats, (SELECT @rank := 0, @prev_score := NULL) AS vars
    ORDER BY 
        TotalScore DESC
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalViews,
    TotalScore,
    TotalBadges,
    ScoreRank
FROM 
    TopUsers
WHERE 
    ScoreRank <= 10 
ORDER BY 
    ScoreRank;
