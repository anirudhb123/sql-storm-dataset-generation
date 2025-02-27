WITH RECURSIVE UserReputationCTE AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        1 AS Level
    FROM
        Users U
    WHERE
        U.Reputation > 1000
    
    UNION ALL

    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        UR.Level + 1 AS Level
    FROM
        Users U
    INNER JOIN UserReputationCTE UR ON U.Reputation < UR.Reputation
)
, PopularPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        PT.Name AS PostTypeName,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM
        Posts P
    INNER JOIN PostTypes PT ON P.PostTypeId = PT.Id
    WHERE
        P.ViewCount > 500
        AND P.Score > 10
)
, UserPostStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments
    FROM
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS CommentCount
        FROM
            Comments
        GROUP BY
            PostId
    ) C ON P.Id = C.PostId
    GROUP BY
        U.Id, U.DisplayName
)
SELECT
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    UR.Level,
    UPS.PostCount,
    UPS.TotalScore,
    UPS.TotalComments,
    PP.Title AS PopularPostTitle,
    PP.ViewCount AS PopularPostViews,
    PP.Score AS PopularPostScore
FROM
    UserReputationCTE UR
LEFT JOIN
    UserPostStats UPS ON UR.UserId = UPS.UserId
LEFT JOIN
    PopularPosts PP ON UPS.PostCount > 0  -- Linking Popular Posts for Users who have posts
ORDER BY
    UR.Reputation DESC, UPS.TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
