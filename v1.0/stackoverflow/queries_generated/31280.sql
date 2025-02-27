WITH RECURSIVE UserVoteCounts AS (
    SELECT U.Id AS UserId, U.DisplayName, COUNT(V.Id) AS TotalVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName

    UNION ALL

    SELECT U.Id, U.DisplayName, COUNT(V.Id) + UVC.TotalVotes
    FROM Users U
    JOIN Votes V ON U.Id = V.UserId
    JOIN UserVoteCounts UVC ON UVC.UserId <> U.Id
    GROUP BY U.Id, U.DisplayName
),

TopUsers AS (
    SELECT UserId, DisplayName, TotalVotes
    FROM UserVoteCounts
    WHERE TotalVotes > 0
    ORDER BY TotalVotes DESC
    LIMIT 10
),

PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotes,
        P.ViewCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY P.Id
    HAVING RANK() <= 10
)

SELECT 
    U.DisplayName AS ActiveUser,
    T.Title,
    T.UpVotes,
    T.DownVotes,
    T.CommentCount,
    T.Score,
    CASE 
        WHEN T.Score > 100 THEN 'High'
        WHEN T.Score BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS ScoreCategory,
    CASE 
        WHEN T.UpVotes IS NULL THEN 'No Upvotes'
        ELSE 'Upvotes Exist'
    END AS UpvoteStatus
FROM TopUsers U
JOIN PostAnalytics T ON U.UserId = T.Id
ORDER BY U.TotalVotes DESC, T.Score DESC;
