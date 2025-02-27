WITH UserVoteSummary AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostSummary AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE((SELECT COUNT(C.Id) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(A.Id) FROM Posts A WHERE A.ParentId = P.Id), 0) AS AnswerCount,
        RANK() OVER (ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '1 month'
)
SELECT
    U.DisplayName,
    U.TotalVotes,
    U.UpVotes,
    U.DownVotes,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.CommentCount,
    P.AnswerCount
FROM UserVoteSummary U
JOIN PostSummary P ON U.UserId = P.OwnerUserId
WHERE U.TotalVotes > 10
ORDER BY P.Score DESC, P.ViewCount DESC
LIMIT 50;

-- Additional metrics for performance benchmarking
SELECT
    COUNT(*) AS TotalPosts,
    AVG(ViewCount) AS AvgViewCount,
    SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
    SUM(CASE WHEN Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts
FROM Posts
WHERE Score IS NOT NULL;
