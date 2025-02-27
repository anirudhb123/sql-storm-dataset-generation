-- Performance benchmarking SQL query
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(V.VoteTypeId = 2, 0)) AS Likes,
        SUM(COALESCE(V.VoteTypeId = 3, 0)) AS Dislikes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.CreationDate >= NOW() - INTERVAL '1 year' -- Considering users active in the last year
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    UserId, 
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalScore,
    TotalViews,
    Likes,
    Dislikes
FROM 
    UserActivity
ORDER BY 
    TotalScore DESC
LIMIT 10; -- Top 10 active users based on total score
