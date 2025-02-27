WITH RECURSIVE UserReputation AS (
    SELECT Id, Reputation
    FROM Users
    WHERE Reputation > 0
    UNION ALL
    SELECT U.Id, U.Reputation + UR.Reputation
    FROM Users U
    JOIN UserReputation UR ON U.Id = UR.Id
    WHERE U.Reputation > 0
),
PostRankings AS (
    SELECT 
        P.Id as PostId,
        P.Title,
        P.CreationDate,
        COUNT(C.ID) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY COUNT(C.ID) DESC, P.CreationDate DESC) as Rank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY P.Id, P.Title, P.CreationDate, P.OwnerUserId
),
TopPosts AS (
    SELECT 
        PR.PostId,
        PR.Title,
        PR.CommentCount,
        PR.UpVotes,
        PR.DownVotes,
        U.DisplayName AS OwnerDisplayName
    FROM PostRankings PR
    JOIN Users U ON PR.OwnerUserId = U.Id
    WHERE PR.Rank <= 5
)
SELECT 
    T.Title,
    T.CommentCount,
    T.UpVotes,
    T.DownVotes,
    U.Reputation AS OwnerReputation,
    COALESCE(REP.Reputation, 0) AS TotalReputation,
    CASE 
        WHEN T.UpVotes > T.DownVotes THEN 'Positive Post'
        WHEN T.UpVotes < T.DownVotes THEN 'Negative Post'
        ELSE 'Neutral Post'
    END AS SentimentAnalysis
FROM TopPosts T
LEFT JOIN Users U ON T.OwnerDisplayName = U.DisplayName
LEFT JOIN UserReputation REP ON U.Id = REP.Id
ORDER BY T.UpVotes DESC;

