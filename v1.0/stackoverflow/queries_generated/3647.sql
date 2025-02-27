WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate,
           ROW_NUMBER() OVER (PARTITION BY CASE WHEN Reputation < 100 THEN 'Low'
                                                WHEN Reputation >= 100 AND Reputation < 1000 THEN 'Medium'
                                                ELSE 'High' END
                              ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostWithVotes AS (
    SELECT P.Id AS PostId, P.Title, P.CreationDate, 
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= '2022-01-01'
    GROUP BY P.Id
),
TopPosts AS (
    SELECT PostId, Title, CreationDate,
           UpVotes - DownVotes AS NetVotes,
           CommentCount,
           RANK() OVER (ORDER BY UpVotes DESC, CreationDate DESC) AS PostRank
    FROM PostWithVotes
    WHERE CommentCount > 5
)
SELECT UR.DisplayName, UR.Reputation, T.PostId, T.Title, T.NetVotes, 
       CASE WHEN T.CommentCount IS NULL THEN 'No Comments' ELSE 'Has Comments' END AS CommentStatus
FROM UserReputation UR
CROSS JOIN TopPosts T
WHERE UR.Reputation > 1000
AND T.PostRank <= 10
AND UR.CreationDate < T.CreationDate
ORDER BY UR.Reputation DESC, T.NetVotes DESC;
