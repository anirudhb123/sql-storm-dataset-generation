WITH UserReputation AS (
    SELECT Id AS UserId, Reputation, CreationDate, LastAccessDate, UpVotes, DownVotes
    FROM Users
    WHERE Reputation > 1000
),
PopularPosts AS (
    SELECT P.Id AS PostId, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount
    FROM Posts P
    JOIN UserReputation UR ON P.OwnerUserId = UR.UserId
    WHERE P.PostTypeId = 1 AND P.ViewCount > 500
),
PostWithComments AS (
    SELECT P.PostId, P.Title, COALESCE(COUNT(C.Id), 0) AS CommentCount
    FROM PopularPosts P
    LEFT JOIN Comments C ON P.PostId = C.PostId
    GROUP BY P.PostId, P.Title
),
PostsWithVotes AS (
    SELECT P.*, COALESCE(V.UpVotes, 0) AS UpVotes, COALESCE(V.DownVotes, 0) AS DownVotes
    FROM PostWithComments P
    LEFT JOIN (
        SELECT PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) V ON P.PostId = V.PostId
)
SELECT P.*, U.DisplayName AS OwnerDisplayName
FROM PostsWithVotes P
JOIN Users U ON P.OwnerUserId = U.Id
WHERE P.CommentCount > 10
ORDER BY P.Score DESC, P.CreationDate DESC
LIMIT 50;
