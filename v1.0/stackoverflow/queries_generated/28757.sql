WITH TagList AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        Id AS PostId
    FROM Posts
    WHERE PostTypeId = 1 -- Considering only Questions
),
TagStats AS (
    SELECT 
        TagName,
        COUNT(DISTINCT PostId) AS PostCount,
        COUNT(*) FILTER (WHERE AnswerCount > 0) AS QuestionsWithAnswers,
        COUNT(*) FILTER (WHERE Score > 0) AS PopularQuestions
    FROM TagList
    INNER JOIN Posts ON TagList.PostId = Posts.Id
    GROUP BY TagName
),
UserActivity AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PopularPosts
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.Reputation > 100 -- Only active users with reputation
    GROUP BY U.Id, U.DisplayName
),
PostHistorySummary AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        P.Title,
        P.Body,
        P.Tags
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId IN (10, 11, 12) -- Filter for closing, reopening, and deletion actions
)
SELECT 
    T.TagName,
    TS.PostCount,
    TS.QuestionsWithAnswers,
    TS.PopularQuestions,
    UA.DisplayName AS ActiveUser,
    UA.PostsCreated,
    UA.PopularPosts,
    PH.PostId,
    PH.Title,
    PH.Body,
    PH.CreationDate AS HistoryDate
FROM TagStats TS
JOIN Users UA ON UA.Id IN (SELECT DISTINCT UserId FROM PostHistorySummary)
JOIN PostHistorySummary PH ON PH.PostId IN (SELECT Id FROM Posts WHERE Tags ILIKE '%' || TS.TagName || '%')
ORDER BY TS.PostCount DESC, UA.PostsCreated DESC, PH.CreationDate DESC
LIMIT 100;
