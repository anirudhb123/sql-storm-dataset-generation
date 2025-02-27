WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(P.Score) AS AverageScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(UPV.TotalViews, 0) AS TotalViews,
        COALESCE(CMT.CommentCount, 0) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount
    FROM Posts P
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount 
        FROM Comments 
        GROUP BY PostId
    ) CMT ON CMT.PostId = P.Id
    LEFT JOIN (
        SELECT PostId, SUM(ViewCount) AS TotalViews 
        FROM Posts 
        GROUP BY PostId
    ) UPV ON UPV.PostId = P.Id
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.TotalViews,
        PS.CommentCount,
        RANK() OVER (ORDER BY PS.Score DESC, PS.TotalViews DESC) AS PostRank
    FROM PostStatistics PS
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    T.Title,
    T.Score,
    T.TotalViews,
    T.CommentCount,
    UA.PostCount,
    UA.UpVotes,
    UA.DownVotes
FROM UserActivity UA
JOIN TopPosts T ON UA.UserId = (
    SELECT P.OwnerUserId
    FROM Posts P
    WHERE P.Id = T.PostId
)
WHERE T.PostRank <= 10
ORDER BY UA.Reputation DESC, T.Score DESC;
