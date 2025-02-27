WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(V.VoteTypeId = 2) AS TotalUpvotes,
        SUM(V.VoteTypeId = 3) AS TotalDownvotes,
        ROUND(AVG(P.Score), 2) AS AvgPostScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
HighReputationUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalUpvotes,
        TotalDownvotes,
        AvgPostScore
    FROM 
        UserStats
    WHERE 
        Reputation > 1000
),
PopularQuestions AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id, P.Title, P.Score, U.DisplayName
    HAVING 
        COUNT(C.Id) > 10 AND AVG(P.Score) > 5
)
SELECT 
    HU.DisplayName,
    HU.TotalPosts,
    HU.TotalQuestions,
    HU.TotalAnswers,
    HU.TotalUpvotes,
    HU.TotalDownvotes,
    HU.AvgPostScore,
    PQ.QuestionId,
    PQ.Title,
    PQ.Score AS QuestionScore,
    PQ.CommentCount
FROM 
    HighReputationUsers HU
JOIN 
    PopularQuestions PQ ON HU.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = PQ.QuestionId)
ORDER BY 
    HU.TotalPosts DESC, PQ.Score DESC
LIMIT 50;
