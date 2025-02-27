
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(IFNULL(P.ViewCount, 0)) AS TotalViews,
        SUM(IFNULL(P.Score, 0)) AS TotalScore,
        SUM(IFNULL(CASE WHEN P.PostTypeId = 1 THEN P.AnswerCount ELSE 0 END, 0)) AS TotalAnswers,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        TotalViews, 
        TotalScore, 
        TotalAnswers, 
        CommentCount,
        @rank := IF(@prev_rank = TotalScore, @rank, @rank + 1) AS Rank,
        @prev_rank := TotalScore
    FROM 
        UserStats, (SELECT @rank := 0, @prev_rank := NULL) AS r
    ORDER BY 
        TotalScore DESC
)

SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalViews,
    TotalScore,
    TotalAnswers,
    CommentCount
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    TotalScore DESC;
