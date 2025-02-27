WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        CASE 
            WHEN U.Reputation > 1000 THEN 'High Reputation'
            WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS Reputation_Category
    FROM Users U
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        H.PostId,
        H.CreationDate,
        H.UserDisplayName,
        C.Name AS CloseReason
    FROM PostHistory H
    JOIN CloseReasonTypes C ON C.Id = CAST(H.Comment AS INT)
    WHERE H.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
),
TopUsers AS (
    SELECT 
        U.DisplayName,
        R.Reputation_Category,
        PS.TotalPosts,
        PS.TotalQuestions,
        PS.TotalAnswers,
        PS.TotalScore,
        PS.TotalViews,
        ROW_NUMBER() OVER (PARTITION BY R.Reputation_Category ORDER BY PS.TotalScore DESC) AS Rank
    FROM UserReputation R
    JOIN PostStatistics PS ON R.UserId = PS.OwnerUserId
    WHERE R.Reputation > 0
)
SELECT 
    U.DisplayName,
    U.Reputation_Category,
    PS.TotalPosts,
    PS.TotalQuestions,
    PS.TotalAnswers,
    PS.TotalScore,
    PS.TotalViews,
    C.CloseReason,
    C.CreationDate AS CloseDate
FROM TopUsers U
LEFT JOIN ClosedPosts C ON U.DisplayName = C.UserDisplayName
WHERE U.Rank <= 5
ORDER BY U.Reputation_Category, U.TotalScore DESC;
This query constructs several Common Table Expressions (CTEs) to aggregate user reputation data, summarize post statistics, identify closed posts along with their reasons, and rank users according to their contribution. It utilizes `LEFT JOIN`, window functions for ranking, and handles closed post reasons via a join with the `CloseReasonTypes` table, showcasing various SQL features and adding complexity through multiple CTEs and conditional aggregations.
