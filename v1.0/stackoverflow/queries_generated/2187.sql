WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate, DisplayName,
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM Users
    WHERE Reputation > 1000
),
PostStatistics AS (
    SELECT P.OwnerUserId,
           COUNT(P.Id) AS TotalPosts,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
           AVG(P.Score) AS AverageScore
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY P.OwnerUserId
),
VotedPosts AS (
    SELECT PostId, COUNT(V.Id) AS VoteCount
    FROM Votes V
    INNER JOIN Posts P ON V.PostId = P.Id
    WHERE V.VoteTypeId = 2  -- Upvote
    GROUP BY PostId
),
TopUsers AS (
    SELECT U.DisplayName,
           COALESCE(PS.TotalPosts, 0) AS TotalPosts,
           COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
           COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
           COALESCE(VP.VoteCount, 0) AS VoteCount,
           UR.UserRank
    FROM UserReputation UR
    LEFT JOIN PostStatistics PS ON UR.Id = PS.OwnerUserId
    LEFT JOIN VotedPosts VP ON PS.OwnerUserId = VP.PostId
    WHERE UR.UserRank <= 10
)
SELECT U.DisplayName,
       T.TotalPosts,
       T.TotalQuestions,
       T.TotalAnswers,
       T.VoteCount,
       (T.TotalAnswers::float / NULLIF(T.TotalQuestions, 0)) AS AnswerToQuestionRatio,
       T.UserRank
FROM TopUsers T
LEFT JOIN Users U ON T.DisplayName = U.DisplayName
ORDER BY T.VoteCount DESC, T.TotalPosts DESC;
