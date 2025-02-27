WITH TagStats AS (
    SELECT
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.ViewCount > 1000 THEN 1 ELSE 0 END) AS PopularityCount,
        AVG(U.Reputation) AS AvgUserReputation
    FROM
        Tags T
    JOIN
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    JOIN
        Users U ON P.OwnerUserId = U.Id
    GROUP BY
        T.TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        PopularityCount,
        AvgUserReputation,
        ROW_NUMBER() OVER (ORDER BY PopularityCount DESC) AS PopularityRank
    FROM
        TagStats
),
ClosedPosts AS (
    SELECT
        PH.PostId,
        COUNT(PH.Id) AS CloseReasonCount,
        STRING_AGG(DISTINCT CRT.Name, ', ') AS CloseReasons
    FROM
        PostHistory PH
    JOIN
        CloseReasonTypes CRT ON PH.Comment::int = CRT.Id
    WHERE
        PH.PostHistoryTypeId IN (10, 11)  -- Post Closed or Post Reopened
    GROUP BY
        PH.PostId
),
PopularClosedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(CP.CloseReasonCount, 0) AS CloseReasonCount,
        COALESCE(CP.CloseReasons, 'None') AS CloseReasons,
        TS.TagName
    FROM
        Posts P
    JOIN
        ClosedPosts CP ON P.Id = CP.PostId
    JOIN
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    JOIN
        TopTags TS ON TS.TagName = T.TagName
    WHERE
        TS.PopularityRank <= 10
)
SELECT
    P.PostId,
    P.Title,
    P.ViewCount,
    P.CloseReasonCount,
    P.CloseReasons,
    P.TagName
FROM
    PopularClosedPosts P
ORDER BY
    P.ViewCount DESC;
