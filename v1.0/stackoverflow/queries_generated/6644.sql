WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        U.Id
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.TotalComments,
    UA.TotalBounties,
    RANK() OVER (ORDER BY UA.Reputation DESC) AS ReputationRank
FROM 
    UserActivity UA
WHERE 
    UA.Reputation > (
        SELECT AVG(Reputation) FROM Users
    )
ORDER BY 
    UA.Reputation DESC, 
    UA.PostCount DESC
LIMIT 10;
