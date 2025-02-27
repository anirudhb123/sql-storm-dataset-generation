
WITH UserReputation AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           U.Reputation,
           @row_num := @row_num + 1 AS ReputationRank
    FROM Users U, (SELECT @row_num := 0) AS r
    WHERE U.Reputation > 0
    ORDER BY U.Reputation DESC
),
PostsSummary AS (
    SELECT P.OwnerUserId,
           COUNT(*) AS TotalPosts,
           SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
           SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
           SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
VoteCounts AS (
    SELECT V.UserId,
           COUNT(*) AS TotalVotes,
           SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN V.VoteTypeId IN (3) THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    GROUP BY V.UserId
)
SELECT U.DisplayName,
       COALESCE(UR.Reputation, 0) AS Reputation,
       COALESCE(PS.TotalPosts, 0) AS PostsCount,
       COALESCE(PS.QuestionsCount, 0) AS QuestionsCount,
       COALESCE(PS.AnswersCount, 0) AS AnswersCount,
       COALESCE(PS.TotalViews, 0) AS TotalViews,
       COALESCE(VC.TotalVotes, 0) AS TotalVotes,
       COALESCE(VC.UpVotes, 0) AS UpVotes,
       COALESCE(VC.DownVotes, 0) AS DownVotes
FROM Users U
LEFT JOIN UserReputation UR ON U.Id = UR.UserId
LEFT JOIN PostsSummary PS ON U.Id = PS.OwnerUserId
LEFT JOIN VoteCounts VC ON U.Id = VC.UserId
WHERE U.Location IS NOT NULL
  AND U.CreationDate < NOW() - INTERVAL 1 YEAR
ORDER BY Reputation DESC, PostsCount DESC
LIMIT 10;
