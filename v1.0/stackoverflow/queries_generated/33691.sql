WITH RECURSIVE UserReputation AS (
    SELECT U.Id, U.Reputation, U.CreationDate, 1 AS Level
    FROM Users U
    WHERE U.Reputation > 1000

    UNION ALL

    SELECT U.Id, U.Reputation, U.CreationDate, UR.Level + 1
    FROM Users U
    JOIN UserReputation UR ON U.Reputation > UR.Reputation
    WHERE U.Reputation > 1000
),
BadgesSummary AS (
    SELECT UserId, COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldCount,
           COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverCount,
           COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeCount
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT P.OwnerUserId, COUNT(P.Id) AS TotalPosts, 
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
           AVG(P.Score) AS AvgScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
VoteAnalysis AS (
    SELECT V.UserId, COUNT(V.Id) AS TotalVotes,
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    GROUP BY V.UserId
),
FinalSummary AS (
    SELECT U.Id AS UserId,
           COALESCE(BS.GoldCount, 0) AS GoldCount,
           COALESCE(BS.SilverCount, 0) AS SilverCount,
           COALESCE(BS.BronzeCount, 0) AS BronzeCount,
           COALESCE(PS.TotalPosts, 0) AS TotalPosts,
           COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
           COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
           COALESCE(VA.TotalVotes, 0) AS TotalVotes,
           COALESCE(VA.UpVotes, 0) AS UpVotes,
           COALESCE(VA.DownVotes, 0) AS DownVotes,
           UR.Level AS ReputationLevel,
           U.Reputation
    FROM Users U
    LEFT JOIN BadgesSummary BS ON U.Id = BS.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN VoteAnalysis VA ON U.Id = VA.UserId
    LEFT JOIN UserReputation UR ON U.Id = UR.Id
    WHERE (U.Reputation IS NOT NULL AND U.Reputation > 500) OR (BS.GoldCount > 0)
)
SELECT UserId, GoldCount, SilverCount, BronzeCount, TotalPosts, TotalQuestions,
       TotalAnswers, TotalVotes, UpVotes, DownVotes, ReputationLevel, Reputation
FROM FinalSummary
ORDER BY Reputation DESC, TotalPosts DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
