WITH TagStatistics AS (
    SELECT
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(U.Reputation) AS AvgReputation,
        STRING_AGG(DISTINCT U.DisplayName, ', ') AS TopContributors
    FROM
        Tags T
    LEFT JOIN
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%' )  -- using simple LIKE for demarcation
    LEFT JOIN
        Users U ON P.OwnerUserId = U.Id
    GROUP BY
        T.TagName
), TagHistory AS (
    SELECT
        TH.TagName,
        COUNT(TH.Id) AS EditHistoryCount,
        MAX(CASE WHEN TH.PostHistoryTypeId = 4 THEN TH.CreationDate END) AS LastTitleEdit,
        MAX(CASE WHEN TH.PostHistoryTypeId = 5 THEN TH.CreationDate END) AS LastBodyEdit,
        MAX(CASE WHEN TH.PostHistoryTypeId = 6 THEN TH.CreationDate END) AS LastTagsEdit
    FROM
        PostHistory TH
    JOIN
        Tags T ON T.ExcerptPostId = TH.PostId
    GROUP BY
        TH.TagName
), FinalStats AS (
    SELECT
        TS.TagName,
        TS.PostCount,
        TS.QuestionCount,
        TS.AnswerCount,
        TS.AvgReputation,
        TS.TopContributors,
        TH.EditHistoryCount,
        TH.LastTitleEdit,
        TH.LastBodyEdit,
        TH.LastTagsEdit
    FROM
        TagStatistics TS
    LEFT JOIN
        TagHistory TH ON TS.TagName = TH.TagName
)

SELECT
    *,
    CASE
        WHEN PostCount > 100 THEN 'Very Active'
        WHEN PostCount BETWEEN 50 AND 100 THEN 'Active'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM
    FinalStats
ORDER BY
    PostCount DESC;
