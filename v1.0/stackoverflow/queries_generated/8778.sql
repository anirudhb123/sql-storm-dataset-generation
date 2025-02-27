WITH UserScore AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           U.Reputation, 
           COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
           COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
           COUNT(DISTINCT P.Id) AS TotalPosts,
           COUNT(DISTINCT C.Id) AS TotalComments,
           COUNT(DISTINCT B.Id) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
), PostActivity AS (
    SELECT P.Id AS PostId, 
           P.Title, 
           P.CreationDate,
           MAX(PH.CreationDate) AS LastActivityDate,
           COUNT(DISTINCT C.Id) AS CommentCount,
           COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
           COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id
), UserPostStats AS (
    SELECT U.UserId,
           U.DisplayName,
           U.Reputation,
           PS.PostId,
           PS.Title,
           PS.CreationDate,
           PS.LastActivityDate,
           PS.CommentCount,
           PS.UpVotes AS PostUpVotes,
           PS.DownVotes AS PostDownVotes
    FROM UserScore U
    JOIN PostActivity PS ON U.UserId = PS.PostId
)
SELECT UPS.DisplayName, 
       UPS.Reputation,
       UPS.Title, 
       UPS.CreationDate, 
       UPS.LastActivityDate, 
       UPS.CommentCount, 
       UPS.PostUpVotes, 
       UPS.PostDownVotes, 
       (UPS.PostUpVotes - UPS.PostDownVotes) AS NetVotes
FROM UserPostStats UPS
WHERE UPS.Reputation > 1000 
ORDER BY UPS.NetVotes DESC, UPS.Reputation DESC
LIMIT 10;
