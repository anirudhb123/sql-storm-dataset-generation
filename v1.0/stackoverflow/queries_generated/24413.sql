WITH CTE_UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.Reputation
),
CTE_PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CTE_BadgeSummary AS (
    SELECT 
        UserId,
        BadgeCount,
        BadgeNames,
        RANK() OVER (ORDER BY BadgeCount DESC) AS BadgeRank
    FROM CTE_UserBadges
),
CTE_FullStats AS (
    SELECT 
        U.DisplayName AS UserDisplayName,
        U.Reputation,
        PS.QuestionCount,
        PS.TotalViews,
        PS.AverageScore,
        BS.BadgeCount,
        BS.BadgeNames,
        CASE WHEN BS.BadgeCount IS NULL THEN 'None' ELSE BS.BadgeNames END AS BadgeSummary
    FROM Users U
    LEFT JOIN CTE_PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN CTE_BadgeSummary BS ON U.Id = BS.UserId
)
SELECT 
    UserDisplayName,
    Reputation,
    COALESCE(QuestionCount, 0) AS Questions,
    COALESCE(TotalViews, 0) AS Views,
    COALESCE(AverageScore, 0) AS AvgScore,
    BadgeSummary,
    CASE 
        WHEN Reputation > 1000 THEN 'High'
        WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS ReputationCategory,
    ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
FROM CTE_FullStats
WHERE Reputation IS NOT NULL
  AND BadgeSummary IS NOT NULL
ORDER BY Reputation DESC, UserDisplayName
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;

-- Additional complex part: Users' Posts with Specific Criteria
UNION ALL
SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation,
    COALESCE(QuestionCount, 0) AS Questions,
    COALESCE(TotalViews, 0) AS Views,
    COALESCE(AverageScore, 0) AS AvgScore,
    'N/A' AS BadgeSummary,
    CASE 
        WHEN COUNT(C.*) > 2 THEN 'Active poster'
        ELSE 'Inactive poster'
    END AS PosterActivity,
    NULL AS UserRank
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN Comments C ON C.PostId = P.Id
WHERE P.ViewCount IS NOT NULL
  AND P.CreationDate >= (NOW() - INTERVAL '1 year')
GROUP BY U.DisplayName, U.Reputation, Questions, TotalViews, AverageScore
HAVING COUNT(P.Id) > 1
ORDER BY U.Reputation DESC
LIMIT 50;

-- Additionally find problematic posts
WITH CTE_ProblematicPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        PH.UserDisplayName,
        PH.Comment AS CloseReason
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE P.PostTypeId = 1 
      AND PH.PostHistoryTypeId IN (10, 12) 
      AND PH.CreationDate >= (NOW() - INTERVAL '3 months')
)
SELECT 
    PP.PostId,
    PP.Title,
    PP.CreationDate,
    PP.UserDisplayName,
    PP.CloseReason,
    CASE 
        WHEN PP.CloseReason IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM CTE_ProblematicPosts PP
ORDER BY PP.CreationDate DESC;
