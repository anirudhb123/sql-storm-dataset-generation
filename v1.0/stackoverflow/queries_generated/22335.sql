WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        AVG(COALESCE(P.Score, 0)) AS AvgScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(PHT.Name, '; ') AS HistoryTypeNames
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE PH.PostHistoryTypeId IN (4, 5, 6, 10, 12) -- Edited Title, Body, Tags, Closed, Deleted
    GROUP BY PH.PostId
),
TopUsers AS (
    SELECT 
        UPS.UserId,
        UPS.DisplayName,
        UP.TotalPosts,
        UP.Questions,
        UP.Answers,
        UP.TotalViews,
        UP.AvgScore,
        ROW_NUMBER() OVER (ORDER BY UP.TotalPosts DESC, UP.AvgScore DESC) AS Rank
    FROM UserPostStats UPS
    JOIN UserPostStats UP ON UPS.UserId = UP.UserId
    WHERE UP.TotalPosts > 0
    ORDER BY UP.TotalPosts DESC, UP.AvgScore DESC
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.Questions,
    TU.Answers,
    TU.TotalViews,
    TU.AvgScore,
    PHS.EditCount,
    PHS.LastEditDate,
    PHS.HistoryTypeNames
FROM TopUsers TU
LEFT JOIN PostHistoryStats PHS ON TU.UserId IN (SELECT OwnerUserId FROM Posts WHERE OwnerUserId IS NOT NULL) 
WHERE TU.Rank <= 10 -- Top 10 users by total posts
AND COALESCE(PHS.EditCount, 0) > 0
ORDER BY TU.TotalPosts DESC, TU.AvgScore DESC;

-- Additional analysis combining CTEs with a full outer join for a quirky comparison
WITH PostsAnalysis AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        CASE WHEN P.Score > 0 THEN 'Positive' ELSE 'Non-Positive' END AS ScoreCategory,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        COUNT(DISTINCT PL.RelatedPostId) AS TotalRelatedPosts
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    GROUP BY P.Id, P.OwnerUserId, P.Score
)
SELECT 
    U.DisplayName,
    PA.ScoreCategory,
    PA.TotalComments,
    PA.TotalRelatedPosts
FROM Users U
FULL OUTER JOIN PostsAnalysis PA ON U.Id = PA.OwnerUserId
WHERE U.Reputation > COALESCE((SELECT AVG(Reputation) FROM Users), 0)
OR PA.TotalComments > 5
ORDER BY PA.TotalComments DESC, U.Reputation DESC;
