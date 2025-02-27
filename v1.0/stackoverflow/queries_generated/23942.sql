WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
TopQuestions AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.AnswerCount,
        P.ViewCount,
        DENSE_RANK() OVER (ORDER BY P.Score DESC) AS ScoreRank
    FROM Posts P
    WHERE P.PostTypeId = 1
),
HighScoringPosts AS (
    SELECT 
        PQ.QuestionId,
        PQ.Title,
        PQ.Score,
        PQ.CreationDate,
        COALESCE(MAX(PH.CreationDate), '1900-01-01') AS LastEditDate,
        COUNT(CASE WHEN C.UserId IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
    FROM TopQuestions PQ
    LEFT JOIN PostHistory PH 
        ON PQ.QuestionId = PH.PostId 
        AND PH.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body or Tags
    LEFT JOIN Comments C 
        ON PQ.QuestionId = C.PostId
    LEFT JOIN Votes V 
        ON PQ.QuestionId = V.PostId AND V.VoteTypeId IN (8, 9) -- BountyStart or BountyClose
    GROUP BY PQ.QuestionId, PQ.Title, PQ.Score, PQ.CreationDate
    HAVING SUM(COALESCE(V.BountyAmount, 0)) > 0 
    OR COUNT(CASE WHEN C.UserId IS NOT NULL THEN 1 END) > 5
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        COUNT(DISTINCT C.Id) AS TotalComments,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - U.CreationDate))) AS AccountAgeSeconds
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id
)

SELECT 
    U.DisplayName,
    UR.Reputation,
    UR.ReputationRank,
    HP.QuestionId,
    HP.Title AS QuestionTitle,
    HP.Score AS QuestionScore,
    HP.CommentCount AS NumberOfComments,
    UAct.TotalAnswers AS UserAnswers,
    UAct.TotalComments AS UserComments,
    UAct.AccountAgeSeconds,
    COALESCE(LT.Name, 'N/A') AS LinkType
FROM HighScoringPosts HP
JOIN UserReputation UR ON UR.UserId = 
    (SELECT OwnerUserId FROM Posts WHERE Id = HP.QuestionId)
JOIN Users U ON U.Id = UR.UserId
LEFT JOIN PostLinks PL ON HP.QuestionId = PL.PostId
LEFT JOIN LinkTypes LT ON PL.LinkTypeId = LT.Id
WHERE (UR.Reputation > 1000 OR U.Location IS NOT NULL) 
  AND U.LastAccessDate > NOW() - INTERVAL '30 days'
ORDER BY HP.Score DESC, U.DisplayName ASC
LIMIT 20;

-- Ensuring empty results handling with NULL logic
SELECT CASE 
            WHEN COUNT(*) = 0 THEN 'No matching records found.'
            ELSE 'Records found.'
        END AS ResultMessage
FROM (
    SELECT 1
    FROM Users U
    LEFT JOIN HighScoringPosts HP ON HP.QuestionId = 
        (SELECT QuestionId FROM HighScoringPosts WHERE QuestionId IS NOT NULL)
    WHERE U.LastAccessDate IS NULL
) AS NullCheck;

