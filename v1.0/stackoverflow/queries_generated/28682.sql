WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score <= 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON V.UserId = U.Id AND V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
), TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostsWithTag,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN P.Id END) AS QuestionsWithAcceptedAnswers
    FROM Tags T
    JOIN Posts P ON T.Id = ANY(string_to_array(P.Tags, '>'::text)::int[])
    GROUP BY T.TagName
), PostHistoryAggregates AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        MAX(CASE WHEN PHT.Name = 'Post Closed' THEN 1 ELSE 0 END) AS IsClosed,
        COUNT(PH.Id) AS EditCount
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY PH.PostId
)
SELECT 
    U.DisplayName,
    US.TotalPosts,
    US.TotalComments,
    US.PositivePosts,
    US.NegativePosts,
    US.TotalBounty,
    T.TagName,
    TS.PostsWithTag,
    TS.TotalViews,
    TS.QuestionsWithAcceptedAnswers,
    PH.LastEditDate,
    PH.IsClosed,
    PH.EditCount
FROM UserStatistics US
JOIN Users U ON U.Id = US.UserId
LEFT JOIN TagStatistics TS ON true -- Placeholder for more complex logic in future joins
LEFT JOIN PostHistoryAggregates PH ON U.Id = PH.PostId
WHERE US.TotalPosts > 10 
    AND US.TotalComments > 5 
    AND TS.PostsWithTag > 0
ORDER BY US.TotalPosts DESC, TS.TotalViews DESC;
