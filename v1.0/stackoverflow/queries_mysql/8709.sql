
WITH UserReputation AS (
    SELECT Id AS UserId, Reputation, 
           @row_number:=IF(@prev_reputation = Reputation, @row_number, @row_number + 1) AS Rank,
           @prev_reputation:=Reputation
    FROM Users, (SELECT @row_number := 0, @prev_reputation := NULL) AS vars
    ORDER BY Reputation DESC
), 
TopUsers AS (
    SELECT UserId, Reputation
    FROM UserReputation
    WHERE Rank <= 10
), 
PostSummary AS (
    SELECT P.Id AS PostId, P.OwnerUserId, P.PostTypeId, 
           COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
           MAX(P.CreationDate) AS RecentActivity
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.OwnerUserId, P.PostTypeId
), 
TopPosts AS (
    SELECT PS.PostId, PS.OwnerUserId, PS.AnswerCount, PS.CommentCount, 
           PS.Upvotes, PS.Downvotes, PS.RecentActivity,
           U.DisplayName
    FROM PostSummary PS
    JOIN Users U ON PS.OwnerUserId = U.Id
    WHERE U.Id IN (SELECT UserId FROM TopUsers)
    ORDER BY PS.Upvotes DESC
    LIMIT 5
)
SELECT 
    TP.PostId, TP.DisplayName AS OwnerName, TP.AnswerCount, 
    TP.CommentCount, TP.Upvotes, TP.Downvotes, 
    UNIX_TIMESTAMP(TP.RecentActivity) AS RecentActivityEpoch
FROM TopPosts TP
ORDER BY TP.Upvotes DESC;
