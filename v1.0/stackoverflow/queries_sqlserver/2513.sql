
WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank,
           NTILE(5) OVER (ORDER BY Reputation) AS ReputationTier
    FROM Users
),

PostStats AS (
    SELECT P.Id, P.Title, P.OwnerUserId, P.CreationDate,
           COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
           COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
           COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
           COUNT(CASE WHEN V.VoteTypeId = 1 THEN 1 END) AS AcceptedVoteCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.OwnerUserId, P.CreationDate, P.AcceptedAnswerId
),

TopPosts AS (
    SELECT PS.Id, PS.Title, PS.UpVoteCount, PS.DownVoteCount, 
           (PS.UpVoteCount - PS.DownVoteCount) AS NetScore,
           UR.ReputationTier
    FROM PostStats PS
    INNER JOIN UserReputation UR ON PS.OwnerUserId = UR.Id
    WHERE PS.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - CAST(30 AS DATETIME)
    ORDER BY NetScore DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)

SELECT T.Id, T.Title, T.UpVoteCount, T.DownVoteCount, 
       T.NetScore, T.ReputationTier,
       COALESCE(CH.CommentCount, 0) AS CommentsMade,
       (SELECT COUNT(*) FROM PostHistory PH WHERE PH.PostId = T.Id AND PH.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount
FROM TopPosts T
LEFT JOIN (SELECT PostId, COUNT(*) AS CommentCount 
            FROM Comments 
            GROUP BY PostId) CH ON T.Id = CH.PostId
ORDER BY T.NetScore DESC, T.ReputationTier ASC;
