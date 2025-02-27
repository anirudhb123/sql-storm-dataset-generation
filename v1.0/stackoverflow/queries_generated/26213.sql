WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.ViewCount > 1000 THEN 1 ELSE 0 END) AS HighViewCountPosts
    FROM
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY
        U.Id, U.DisplayName, U.Reputation
),
BadgeCounts AS (
    SELECT
        B.UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Badges B
    GROUP BY
        B.UserId
),
PopularTags AS (
    SELECT
        Tags.TagName,
        COUNT(P.Id) AS PostCount
    FROM
        Tags
    JOIN Posts P ON Tags.Id = ANY(string_to_array(P.Tags, '><')::int[])
    GROUP BY
        Tags.TagName
    HAVING
        COUNT(P.Id) > 10
),
PostStatistics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM
        Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN LATERAL string_to_array(P.Tags, '><') AS T(Tag) ON TRUE
    LEFT JOIN Tags T ON T.TagName = T.Tag
    GROUP BY
        P.Id
)
SELECT
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    BC.TotalBadges,
    BC.GoldBadges,
    BC.SilverBadges,
    BC.BronzeBadges,
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.CreationDate,
    PS.TotalComments,
    PS.Tags
FROM
    UserReputation U
LEFT JOIN BadgeCounts BC ON U.UserId = BC.UserId
LEFT JOIN PostStatistics PS ON U.UserId = PS.OwnerUserId
ORDER BY
    U.Reputation DESC,
    PS.ViewCount DESC
LIMIT 100;
