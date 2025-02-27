WITH UserTagInteraction AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT T.Id) AS TagCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        AVG(U.Reputation) AS AverageReputation
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    JOIN unnest(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')) AS TagName ON TRUE
    JOIN Tags T ON T.TagName = TagName
    LEFT JOIN Comments C ON C.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
),
PostHistorySummary AS (
    SELECT 
        PH.UserId,
        COUNT(DISTINCT PH.Id) AS EditCount,
        COUNT(DISTINCT PH.PostId) AS EditedPostCount,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT P.Title) AS EditedPostTitles
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
    GROUP BY PH.UserId
),
FinalSummary AS (
    SELECT 
        UTI.UserId,
        UTI.DisplayName,
        UTI.TagCount,
        UTI.QuestionCount,
        UTI.AnswerCount,
        UTI.CommentCount,
        UTI.AverageReputation,
        PHS.EditCount,
        PHS.EditedPostCount,
        PHS.LastEditDate,
        PHS.EditedPostTitles
    FROM UserTagInteraction UTI
    LEFT JOIN PostHistorySummary PHS ON UTI.UserId = PHS.UserId
)
SELECT 
    UserId,
    DisplayName,
    TagCount,
    QuestionCount,
    AnswerCount,
    CommentCount,
    AverageReputation,
    COALESCE(EditCount, 0) AS EditCount,
    COALESCE(EditedPostCount, 0) AS EditedPostCount,
    COALESCE(LastEditDate::timestamp, '1970-01-01 00:00:00') AS LastEditDate,
    COALESCE(EditedPostTitles, 'No Edits') AS EditedPostTitles
FROM FinalSummary
ORDER BY AverageReputation DESC, TagCount DESC
LIMIT 10;
