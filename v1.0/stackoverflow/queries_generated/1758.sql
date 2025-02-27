WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM
        Users U
),
PostStatistics AS (
    SELECT
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS TotalComments,
        COUNT(CASE WHEN V.PostId IS NOT NULL THEN 1 END) AS TotalVotes,
        AVG(P.Score) AS AvgScore
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    GROUP BY
        P.Id, P.OwnerUserId
),
ClosedPostsWithComments AS (
    SELECT
        P.Id AS ClosedPostId,
        P.Title,
        PH.CreationDate AS CloseDate,
        PS.TotalComments,
        PS.TotalVotes,
        PS.AvgScore,
        U.DisplayName
    FROM
        Posts P
    JOIN
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    JOIN
        PostStatistics PS ON P.Id = PS.PostId
    JOIN
        Users U ON P.OwnerUserId = U.Id
    WHERE
        PH.CreationDate > NOW() - INTERVAL '30 days'
),
UserDetails AS (
    SELECT
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        COALESCE(CW.ClosedPostCount, 0) AS ClosedPostCount
    FROM
        UserReputation UR
    LEFT JOIN (
        SELECT
            OwnerUserId,
            COUNT(*) AS ClosedPostCount
        FROM
            ClosedPostsWithComments
        GROUP BY
            OwnerUserId
    ) CW ON UR.UserId = CW.OwnerUserId
)
SELECT
    UD.DisplayName,
    UD.Reputation,
    UD.ClosedPostCount,
    C.Title AS ClosedPostTitle,
    C.CloseDate,
    C.TotalComments,
    C.TotalVotes,
    C.AvgScore
FROM
    UserDetails UD
LEFT JOIN
    ClosedPostsWithComments C ON UD.UserId = C.ClosedPostId
ORDER BY
    UD.Reputation DESC,
    UD.ClosedPostCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
