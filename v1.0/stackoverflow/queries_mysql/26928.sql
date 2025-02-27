
WITH PostTagCounts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerDisplayName,
        P.ViewCount,
        COUNT(T.TagName) AS TagCount,
        GROUP_CONCAT(DISTINCT T.TagName SEPARATOR ', ') AS TagList
    FROM
        Posts P
    LEFT JOIN
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
            (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
             UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
         WHERE 
            CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1) AS tag ON TRUE
    LEFT JOIN
        Tags T ON T.TagName = tag.TagName
    WHERE
        P.PostTypeId = 1 
    GROUP BY
        P.Id, P.Title, P.CreationDate, P.OwnerDisplayName, P.ViewCount
),
RecentClosedPosts AS (
    SELECT
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        P.Title,
        U.DisplayName AS ClosedBy
    FROM
        PostHistory PH
    JOIN
        Posts P ON PH.PostId = P.Id
    JOIN
        Users U ON PH.UserId = U.Id
    WHERE
        PH.PostHistoryTypeId = 10 
        AND PH.CreationDate >= NOW() - INTERVAL 30 DAY
),
TopContributors AS (
    SELECT
        U.Id,
        U.DisplayName,
        COUNT(P.Id) AS QuestionCount,
        SUM(P.ViewCount) AS TotalViews
    FROM
        Users U
    JOIN
        Posts P ON U.Id = P.OwnerUserId
    WHERE
        P.PostTypeId = 1 
    GROUP BY
        U.Id, U.DisplayName
    ORDER BY
        QuestionCount DESC
    LIMIT 10
)

SELECT
    PTC.PostId,
    PTC.Title,
    PTC.CreationDate,
    PTC.OwnerDisplayName,
    PTC.TagCount,
    PTC.TagList,
    RCP.CreationDate AS ClosedDate,
    RCP.ClosedBy,
    TCC.DisplayName AS TopContributor,
    TCC.QuestionCount,
    TCC.TotalViews
FROM
    PostTagCounts PTC
LEFT JOIN
    RecentClosedPosts RCP ON PTC.PostId = RCP.PostId
LEFT JOIN
    TopContributors TCC ON PTC.OwnerDisplayName = TCC.DisplayName
ORDER BY
    PTC.CreationDate DESC
LIMIT 50;
