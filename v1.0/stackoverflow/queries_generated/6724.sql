WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        AVG(P.Score) AS AvgPostScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments
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
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        AvgPostScore,
        TotalViews,
        TotalComments,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.TotalPosts,
    T.TotalAnswers,
    T.TotalQuestions,
    T.AvgPostScore,
    T.TotalViews,
    T.TotalComments
FROM 
    TopUsers T
WHERE 
    T.Rank <= 10
ORDER BY 
    T.TotalPosts DESC;
