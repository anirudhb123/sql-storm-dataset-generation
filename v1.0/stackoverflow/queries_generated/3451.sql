WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        AVG(U.Reputation) OVER (PARTITION BY U.Location) AS AvgReputationInLocation,
        MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostsCount,
        RANK() OVER (ORDER BY COUNT(P.Id) DESC) AS PopularityRank
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
    HAVING COUNT(P.Id) > 10
),
ClosedPostDetails AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseVotes,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId
)
SELECT 
    UA.DisplayName,
    UA.TotalPosts,
    UA.QuestionsCount,
    UA.AnswersCount,
    UA.AvgReputationInLocation,
    PT.TagName AS PopularTag,
    PT.PostsCount AS TagPostCount,
    CP.CloseVotes,
    CP.LastClosedDate
FROM UserActivity UA
LEFT JOIN PopularTags PT ON UA.QuestionsCount > 5
LEFT JOIN ClosedPostDetails CP ON CP.PostId IN (
    SELECT Id FROM Posts WHERE OwnerUserId = UA.UserId AND AcceptedAnswerId IS NOT NULL
)
ORDER BY UA.TotalPosts DESC, PT.PostsCount DESC
FETCH FIRST 50 ROWS ONLY;
