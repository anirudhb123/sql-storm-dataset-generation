
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        @user_rank := @user_rank + 1 AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.Views
    ORDER BY U.Reputation DESC,
    (SELECT @user_rank := 0)
), RecentPostStats AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        @recent_rank := @recent_rank + 1 AS RecentRank
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY P.LastActivityDate DESC,
    (SELECT @recent_rank := 0)
), PostHistoryAggregates AS (
    SELECT 
        Ph.PostId,
        COUNT(*) AS EditCount,
        MAX(Ph.CreationDate) AS LastEditDate,
        GROUP_CONCAT(DISTINCT PHT.Name ORDER BY PHT.Name SEPARATOR ', ') AS EditTypes
    FROM PostHistory Ph
    JOIN PostHistoryTypes PHT ON Ph.PostHistoryTypeId = PHT.Id
    GROUP BY Ph.PostId
), TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
), PopularPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.ViewCount,
        @popularity_rank := @popularity_rank + 1 AS PopularityRank
    FROM Posts P
    WHERE P.Score > 10 AND P.ViewCount > 100
    ORDER BY P.Score DESC,
    (SELECT @popularity_rank := 0)
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.Views,
    U.TotalPosts,
    U.TotalAnswers,
    U.TotalQuestions,
    U.TotalBounty,
    R.Title AS RecentPostTitle,
    R.CreationDate AS RecentPostDate,
    PH.EditCount AS TotalEdits,
    PH.LastEditDate AS LastEditedDate,
    PH.EditTypes,
    T.TagName,
    T.PostCount AS TagPostCount,
    T.TotalViews AS TagTotalViews,
    P.Title AS PopularPostTitle,
    P.Score AS PopularPostScore,
    P.ViewCount AS PopularPostViewCount
FROM UserStatistics U
LEFT JOIN RecentPostStats R ON U.UserId = R.Id
LEFT JOIN PostHistoryAggregates PH ON U.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = PH.PostId)
LEFT JOIN TagStats T ON T.TotalViews > 1000
LEFT JOIN PopularPosts P ON U.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = P.Id)
WHERE U.Reputation > 50
ORDER BY U.UserRank, R.RecentRank, PH.EditCount DESC
LIMIT 100;
