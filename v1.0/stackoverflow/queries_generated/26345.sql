WITH TagStats AS (
    SELECT
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS TopAuthors
    FROM
        Tags T
    LEFT JOIN
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN
        Users U ON P.OwnerUserId = U.Id
    WHERE
        P.PostTypeId = 1 -- Filtering only Questions
    GROUP BY
        T.TagName
),
RecentActivity AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        PH.UserDisplayName AS LastEditor,
        PH.CreationDate AS LastEditDate
    FROM
        Posts P
    JOIN
        PostHistory PH ON P.Id = PH.PostId
    WHERE
        PH.PostHistoryTypeId IN (4, 5) -- Edit Title or Edit Body
        AND PH.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT
    TS.TagName,
    TS.PostCount,
    TS.TotalViews,
    TS.AverageScore,
    TS.TopAuthors,
    RA.Title,
    RA.CreationDate AS PostCreationDate,
    RA.LastEditor,
    RA.LastEditDate
FROM
    TagStats TS
LEFT JOIN
    RecentActivity RA ON TS.TagName = SPLIT_PART(RA.Title, ' ', 1) -- Assuming title starts with tag name
ORDER BY
    TS.PostCount DESC, TS.TotalViews DESC
LIMIT 10;
