
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(IFNULL(P.Score, 0)) AS TotalScore,
        SUM(IFNULL(P.ViewCount, 0)) AS TotalViews,
        SUM(IFNULL(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS TotalQuestions,
        SUM(IFNULL(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS TotalAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalScore,
        TotalViews,
        TotalQuestions,
        TotalAnswers,
        @rownum := @rownum + 1 AS Rank
    FROM 
        UserStats, (SELECT @rownum := 0) r
    ORDER BY 
        TotalScore DESC
)
SELECT 
    Rank,
    DisplayName,
    TotalPosts,
    TotalScore,
    TotalViews,
    TotalQuestions,
    TotalAnswers
FROM 
    TopUsers
WHERE 
    Rank <= 10;
