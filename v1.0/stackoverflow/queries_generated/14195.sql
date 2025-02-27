-- Performance benchmarking query

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id,
        U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        CASE 
            WHEN P.PostTypeId = 1 THEN 'Question'
            WHEN P.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType,
        T.TagName AS PostTag
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON T.Id = ANY(STRING_TO_ARRAY(P.Tags, ',')::int[])
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.TotalScore,
    U.TotalViews,
    U.TotalAnswers,
    U.TotalComments,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.LastActivityDate,
    P.Score,
    P.PostType,
    P.PostTag
FROM 
    UserStats U
JOIN 
    PostDetails P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.Reputation DESC, U.PostCount DESC;
