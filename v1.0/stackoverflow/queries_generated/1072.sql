WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(COALESCE(P.Score, 0)) AS AvgScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS TagUsageCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
    HAVING COUNT(P.Id) > 10
),
PostDetail AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS AuthorName,
        PT.Name AS PostType,
        COALESCE(CT.reason, 'N/A') AS CloseReason
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    LEFT JOIN CloseReasonTypes CT ON PH.Comment::int = CT.Id
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.AvgScore,
    UPS.LastPostDate,
    PT.Title AS RecentPostTitle,
    PT.PostType,
    PT.CloseReason,
    (SELECT STRING_AGG(TAG.TagName, ', ') FROM PopularTags TAG WHERE TAG.TagUsageCount > 5) AS PopularTags
FROM UserPostStats UPS
LEFT JOIN PostDetail PT ON UPS.UserId = PT.AuthorName
WHERE UPS.TotalPosts > 0
ORDER BY UPS.AvgScore DESC, UPS.TotalPosts DESC
LIMIT 10;
