WITH RECURSIVE UserReputationLevels AS (
    SELECT Id, Reputation, 
           CASE 
               WHEN Reputation >= 20000 THEN 'Legend'
               WHEN Reputation >= 10000 THEN 'Hero'
               WHEN Reputation >= 5000  THEN 'Veteran'
               WHEN Reputation >= 1000  THEN 'Experienced'
               WHEN Reputation >= 0     THEN 'Novice'
               ELSE 'Unknown'
           END AS ReputationLevel
    FROM Users
), 

PostVoteDetails AS (
    SELECT P.Id AS PostId,
           P.Title,
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Score
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
),

RecentPostComments AS (
    SELECT C.PostId, 
           COUNT(C.Id) AS CommentCount,
           MAX(C.CreationDate) AS LastCommentDate
    FROM Comments C
    WHERE C.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY C.PostId
)

SELECT U.Id AS UserId,
       U.DisplayName,
       UReputation.ReputationLevel,
       P.Id AS PostId, 
       P.Title,
       PVD.UpVotes,
       PVD.DownVotes,
       PVD.Score,
       RPC.CommentCount,
       COALESCE(RPC.LastCommentDate, 'No comments') AS LastCommentDate
FROM Users U
JOIN UserReputationLevels UReputation ON U.Id = UReputation.Id
JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN PostVoteDetails PVD ON P.Id = PVD.PostId
LEFT JOIN RecentPostComments RPC ON P.Id = RPC.PostId
WHERE U.Reputation >= 1000
  AND P.CreationDate >= NOW() - INTERVAL '1 year'
  AND (P.ViewCount > 50 OR P.CommentCount > 5)
ORDER BY U.Reputation DESC, PVD.Score DESC;

