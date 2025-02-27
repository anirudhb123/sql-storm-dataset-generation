
WITH UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
    FROM
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PostStatistics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        CASE
            WHEN P.PostTypeId = 1 THEN 'Question'
            WHEN P.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        P.ViewCount
    FROM
        Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY
        P.Id, P.Title, P.CreationDate, P.PostTypeId, P.ViewCount
),
TopUsers AS (
    SELECT
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.CreationDate,
        UA.TotalPosts,
        UA.TotalComments,
        UA.TotalBounty,
        @rank := IF(@prev_total_posts = UA.TotalPosts, @rank, @rank + 1) AS Rank,
        @prev_total_posts := UA.TotalPosts
    FROM
        UserActivity UA,
        (SELECT @rank := 0, @prev_total_posts := NULL) AS vars
    ORDER BY
        UA.TotalPosts DESC, UA.TotalBounty DESC
)
SELECT
    PU.PostId,
    PU.Title,
    PU.CreationDate,
    PU.PostType,
    PU.CommentCount,
    PU.UpVotes,
    PU.DownVotes,
    TU.DisplayName AS TopUser,
    TU.Reputation AS TopUserReputation,
    TU.TotalPosts AS TopUserPosts,
    TU.TotalBounty AS TopUserBounty
FROM
    PostStatistics PU
LEFT JOIN TopUsers TU ON TU.Rank = 1
WHERE
    PU.ViewCount <= 10
ORDER BY
    PU.ViewCount DESC;
