WITH UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        COUNT(DISTINCT V.Id) AS VoteCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(COALESCE(C.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments
    FROM
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON V.UserId = U.Id
    LEFT JOIN Badges B ON B.UserId = U.Id
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS CommentCount,
            SUM(ViewCount) AS ViewCount
        FROM
            Comments C
        JOIN Posts P ON C.PostId = P.Id
        GROUP BY
            PostId
    ) C ON C.PostId = P.Id
    GROUP BY
        U.Id, U.DisplayName
)
SELECT
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    VoteCount,
    BadgeCount,
    TotalViews,
    TotalComments
FROM
    UserActivity
ORDER BY
    PostCount DESC, TotalScore DESC
LIMIT 10;
