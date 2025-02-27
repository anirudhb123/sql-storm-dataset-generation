WITH RecursiveCTE AS (
    SELECT P.Id, P.Title, P.CreationDate, P.Score, P.AcceptedAnswerId, 0 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1  -- Selecting questions
    UNION ALL
    SELECT P.Id, P.Title, P.CreationDate, P.Score, P.AcceptedAnswerId, Level + 1
    FROM Posts P
    INNER JOIN Posts Answers ON P.Id = Answers.ParentId
    WHERE Answers.PostTypeId = 2  -- Selecting answers
      AND Level < 2  -- Limiting depth to prevent excessive recursion
),
VoteCTE AS (
    SELECT V.PostId, SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    GROUP BY V.PostId
),
UserBadges AS (
    SELECT U.Id AS UserId, B.Class, COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, B.Class
),
PostScores AS (
    SELECT P.Id AS PostId, 
           COALESCE(V.UpVotes, 0) AS TotalUpVotes, 
           COALESCE(V.DownVotes, 0) AS TotalDownVotes, 
           P.Score + COALESCE(V.UpVotes, 0) - COALESCE(V.DownVotes, 0) AS NetScore,
           U.Reputation AS UserReputation
    FROM Posts P
    LEFT JOIN VoteCTE V ON P.Id = V.PostId
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
),
FinalResults AS (
    SELECT R.Id, R.Title, R.CreationDate, P.NetScore, 
           R.Level, U.Reputation, UB.BadgeCount,
           CASE 
               WHEN P.NetScore >= 10 THEN 'High Score'
               WHEN P.NetScore BETWEEN 1 AND 9 THEN 'Moderate Score'
               ELSE 'Low Score'
           END AS ScoreCategory
    FROM RecursiveCTE R
    JOIN PostScores P ON R.Id = P.PostId
    LEFT JOIN UserBadges UB ON P.UserReputation = UB.UserId 
)
SELECT FR.Title, FR.CreationDate, FR.NetScore, FR.ScoreCategory, 
       FR.Level, FR.Reputation, FR.BadgeCount
FROM FinalResults FR
ORDER BY FR.NetScore DESC, FR.CreationDate ASC
LIMIT 100;

