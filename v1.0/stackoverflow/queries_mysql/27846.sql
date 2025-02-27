
WITH TagFrequencies AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    INNER JOIN (
        SELECT 
            1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
            SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
            SELECT 9 UNION ALL SELECT 10
    ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE
        PostTypeId = 1 
    GROUP BY
        TagName
),
FrequentTags AS (
    SELECT
        TagName,
        PostCount
    FROM
        TagFrequencies
    WHERE
        PostCount > 5 
),
TopUsers AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM
        Users U
    JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    WHERE
        U.Reputation > 1000 
    GROUP BY
        U.Id, U.DisplayName
),
TaggedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        F.TagName,
        P.OwnerUserId
    FROM
        Posts P
    JOIN
        FrequentTags F ON F.TagName IN (SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', n.n), '><', -1))
    INNER JOIN (
        SELECT 
            1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
            SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
            SELECT 9 UNION ALL SELECT 10
    ) n ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= n.n - 1
    WHERE
        P.PostTypeId = 1 
)
SELECT
    TU.DisplayName,
    COUNT(DISTINCT TP.PostId) AS TaggedPostCount,
    SUM(TP.ViewCount) AS TotalViewsFromTaggedPosts,
    SUM(TP.Score) AS TotalScoreFromTaggedPosts,
    SUM(TU.TotalViews) AS TotalViewsByUser,
    SUM(TU.TotalScore) AS TotalScoreByUser,
    TU.TotalComments
FROM
    TopUsers TU
JOIN
    TaggedPosts TP ON TU.UserId = TP.OwnerUserId
GROUP BY
    TU.DisplayName, TU.TotalViews, TU.TotalScore, TU.TotalComments
ORDER BY
    TaggedPostCount DESC, TotalViewsFromTaggedPosts DESC;
