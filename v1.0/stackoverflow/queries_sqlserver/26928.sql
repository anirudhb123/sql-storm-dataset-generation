
WITH PostTagCounts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerDisplayName,
        P.ViewCount,
        COUNT(T.TagName) AS TagCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagList
    FROM
        Posts P
    LEFT JOIN
        STRING_SPLIT(SUBSTRING(P.Tags, 2, LEN(P.Tags) - 2), '>') AS tag ON 1=1
    LEFT JOIN
        Tags T ON T.TagName = tag.value
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
        AND PH.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '30 DAY'
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
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
