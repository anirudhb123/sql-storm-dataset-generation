
WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(ISNULL(P.Score, 0)) AS TotalScore
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
),

TopTags AS (
    SELECT
        T.TagName,
        COUNT(P.Id) AS UsageCount
    FROM
        Tags T
    JOIN
        Posts P ON P.Tags LIKE '%' + '<' + T.TagName + '>%'
    GROUP BY
        T.TagName
    ORDER BY
        UsageCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),

UserBadges AS (
    SELECT
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users U
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id
),

PostStatistics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        T.TagName
    FROM
        Posts P
    CROSS JOIN
        TopTags T
    WHERE
        P.Tags LIKE '%' + '<' + T.TagName + '>%'
    ORDER BY
        P.CreationDate DESC
    OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
)

SELECT
    U.DisplayName,
    U.Reputation,
    UR.PostCount,
    UR.TotalScore,
    UB.BadgeCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.AnswerCount,
    PS.CommentCount,
    PS.TagName
FROM
    UserReputation UR
JOIN
    Users U ON UR.UserId = U.Id
LEFT JOIN
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN
    PostStatistics PS ON U.Id = (SELECT OwnerUserId FROM Posts WHERE Id = PS.PostId)
ORDER BY
    U.Reputation DESC, PS.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
