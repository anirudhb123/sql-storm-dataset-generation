WITH UserBadgeCount AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
RecentPosts AS (
    SELECT P.Id, P.Title, P.CreationDate, P.OwnerUserId, P.Score,
           RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
),
TopUsers AS (
    SELECT U.Id, U.DisplayName, U.Reputation, COALESCE(UB.BadgeCount, 0) AS BadgeCount
    FROM Users U
    LEFT JOIN UserBadgeCount UB ON U.Id = UB.UserId
    WHERE U.Reputation > 1000
)
SELECT TU.DisplayName, TU.Reputation, TU.BadgeCount, RP.Title AS RecentPostTitle, RP.CreationDate
FROM TopUsers TU
LEFT JOIN RecentPosts RP ON TU.Id = RP.OwnerUserId
WHERE RP.PostRank = 1 OR RP.PostRank IS NULL
ORDER BY TU.Reputation DESC, TU.BadgeCount DESC
LIMIT 10;

SELECT DISTINCT T.TagName
FROM Tags T
WHERE T.Count >= (
    SELECT AVG(T2.Count)
    FROM Tags T2
)
UNION ALL
SELECT T.TagName
FROM Tags T
WHERE T.IsModeratorOnly = 1
ORDER BY TagName;

SELECT P.Id, P.Title, 
       (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
       (SELECT COUNT(V.UserId) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount,
       (SELECT COUNT(V.UserId) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVoteCount
FROM Posts P
WHERE P.Title ILIKE '%SQL%'
AND P.CreationDate >= NOW() - INTERVAL '1 year'
ORDER BY P.LastActivityDate DESC
LIMIT 5;

WITH ClosedPosts AS (
    SELECT P.Id, P.Title, PH.CreationDate AS ClosedDate, 
           COUNT(C.Id) AS CommentCount
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE PH.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY P.Id, P.Title, PH.CreationDate
)
SELECT C.Title, C.ClosedDate, COALESCE(C.CommentCount, 0) AS TotalComments
FROM ClosedPosts C
LEFT JOIN (
    SELECT PO.Id, PO.Title
    FROM Posts PO
    WHERE PO.PostTypeId = 1 -- Only Questions
    AND PO.AnswerCount > 0
) AS Q ON C.Id = Q.Id
ORDER BY C.ClosedDate DESC;

SELECT U.DisplayName, COUNT(P.Id) AS PostCount
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
WHERE U.Location IS NOT NULL
GROUP BY U.DisplayName
HAVING COUNT(P.Id) > 10
ORDER BY COUNT(P.Id) DESC;
