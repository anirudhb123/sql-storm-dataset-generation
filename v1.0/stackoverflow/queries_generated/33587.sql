WITH RecursivePostCTE AS (
    SELECT P.Id, P.Title, P.PostTypeId, P.AcceptedAnswerId, P.OwnerUserId, P.CreationDate,
           0 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1 -- Only Questions
    UNION ALL
    SELECT P.Id, P.Title, P.PostTypeId, P.AcceptedAnswerId, P.OwnerUserId, P.CreationDate,
           Level + 1
    FROM Posts P
    INNER JOIN RecursivePostCTE R ON P.ParentId = R.Id -- Get answers for questions
),
UserReputation AS (
    SELECT U.Id AS UserId, U.Reputation,
           COUNT(DISTINCT B.Id) AS BadgeCount,
           SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViews
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.Reputation
),
VotesSummary AS (
    SELECT V.PostId,
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    GROUP BY V.PostId
)
SELECT RP.Id AS QuestionId, RP.Title, UReputation.Reputation, UReputation.BadgeCount,
       UReputation.TotalViews, COALESCE(VS.UpVotes, 0) AS UpVotes, COALESCE(VS.DownVotes, 0) AS DownVotes
FROM RecursivePostCTE RP
INNER JOIN Users U ON RP.OwnerUserId = U.Id
INNER JOIN UserReputation UReputation ON U.Id = UReputation.UserId
LEFT JOIN VotesSummary VS ON RP.Id = VS.PostId
WHERE RP.CreationDate >= NOW() - INTERVAL '1 year' 
  AND UReputation.Reputation > 1000
ORDER BY UpVotes DESC, RP.CreationDate DESC;
