WITH UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounty
    FROM
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY
        U.Id
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
        SUM(COALESCE(V.VoteTypeId = 2, 0)) AS UpVotes,
        SUM(COALESCE(V.VoteTypeId = 3, 0)) AS DownVotes,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.ViewCount DESC) AS ViewRank
    FROM
        Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY
        P.Id
),
TopUsers AS (
    SELECT
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        UA.TotalPosts,
        UA.TotalComments,
        UA.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY UA.TotalPosts DESC, UA.TotalBounty DESC) AS Rank
    FROM
        UserActivity UA
    JOIN Users U ON A.UserId = U.Id
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
    PU.ViewRank <= 10
ORDER BY
    PU.ViewCount DESC
OPTION (RECOMPILE);
