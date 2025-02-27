WITH RecursivePostCTE AS (
    SELECT P.Id AS PostId,
           P.Title,
           P.CreationDate,
           P.OwnerUserId,
           1 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1  -- Questions
    UNION ALL
    SELECT P2.Id AS PostId,
           P2.Title,
           P2.CreationDate,
           P2.OwnerUserId,
           Level + 1 
    FROM Posts P2
    INNER JOIN RecursivePostCTE R ON R.PostId = P2.ParentId
),
UserStats AS (
    SELECT U.Id AS UserId,
           U.DisplayName,
           U.Reputation,
           COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
           COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
           COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
AvgScores AS (
    SELECT P.OwnerUserId,
           AVG(P.Score) AS AvgPostScore,
           COUNT(DISTINCT P.Id) AS PostCount
    FROM Posts P
    WHERE P.PostTypeId IN (1, 2)  -- Questions and Answers
    GROUP BY P.OwnerUserId
),
PostHistorySummary AS (
    SELECT PH.UserId,
           COUNT(PH.Id) AS TotalHistoryEdits,
           COUNT(DISTINCT PH.PostId) AS UniquePostsEdited
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 6, 10)  -- Title edits, Tag edits, Post closed
    GROUP BY PH.UserId
)
SELECT U.Id AS UserId,
       U.DisplayName,
       U.Reputation,
       US.Upvotes,
       US.Downvotes,
       COALESCE(AvgScores.AvgPostScore, 0) AS AvgPostScore,
       COALESCE(AvgScores.PostCount, 0) AS PostCount,
       COALESCE(PHS.TotalHistoryEdits, 0) AS TotalEdits,
       COALESCE(PHS.UniquePostsEdited, 0) AS UniquePostsEdited,
       COUNT(DISTINCT P.Id) AS TotalQuestionsWithAcceptedAnswer
FROM Users U
LEFT JOIN UserStats US ON U.Id = US.UserId
LEFT JOIN AvgScores ON U.Id = AvgScores.OwnerUserId
LEFT JOIN PostHistorySummary PHS ON U.Id = PHS.UserId
LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.AcceptedAnswerId IS NOT NULL
GROUP BY U.Id, U.DisplayName, U.Reputation, US.Upvotes, US.Downvotes, AvgScores.AvgPostScore, AvgScores.PostCount, PHS.TotalHistoryEdits, PHS.UniquePostsEdited
ORDER BY U.Reputation DESC, US.Upvotes DESC
LIMIT 100;
