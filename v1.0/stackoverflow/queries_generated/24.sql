WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(V.Id) DESC) AS UserRank
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    WHERE U.Reputation > 100
    GROUP BY U.Id
),
PostWithComments AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(COUNT(C.Id), 0) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY P.Id
),
TopPosts AS (
    SELECT 
        P.PostId,
        P.Title,
        P.CommentCount,
        ROW_NUMBER() OVER (ORDER BY P.CommentCount DESC) AS Rank
    FROM PostWithComments P
)
SELECT 
    U.DisplayName,
    U.Reputation,
    T.Title,
    T.CommentCount,
    CASE 
        WHEN UVs.UpVotes > 0 THEN 'Active Contributor'
        ELSE 'New User'
    END AS UserStatus,
    NVL(PH.LastActivity, 'No activity recorded') AS LastActivity
FROM UserVoteSummary UVs
JOIN Users U ON UVs.UserId = U.Id
JOIN TopPosts T ON T.Rank <= 10
LEFT JOIN (
    SELECT 
        PostId,
        MAX(LastActivityDate) AS LastActivity
    FROM Posts
    GROUP BY PostId
) PH ON PH.PostId = T.PostId
WHERE UVs.UserRank <= 10
ORDER BY U.Reputation DESC, T.CommentCount DESC;
