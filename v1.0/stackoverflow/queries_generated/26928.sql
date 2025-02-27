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
        UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')) AS tag (TagName) ON TRUE
    LEFT JOIN
        Tags T ON T.TagName = tag.TagName
    WHERE
        P.PostTypeId = 1 -- Only questions
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
        PH.PostHistoryTypeId = 10 -- Post Closed
        AND PH.CreationDate >= now() - interval '30 days'
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
        P.PostTypeId = 1 -- Only questions
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

This SQL query performs the following interesting tasks on the Stack Overflow schema:

1. It counts the number of tags associated with each question while also aggregating distinct tag names into a comma-separated list, generating a summary for all questions.
  
2. It gathers the most recent 30-day closed posts, capturing details such as closure date, title, and the display name of the user who closed them.

3. It identifies the top contributors (users) based on the number of questions posted and total views acquired, limiting results to the top 10.

Finally, the main SELECT statement combines these CTEs (Common Table Expressions) to generate a comprehensive result set, detailing each question alongside its various metrics regarding tags, closure status, and contributor statistics, producing a rich dataset useful for performance benchmarking and analysis.
