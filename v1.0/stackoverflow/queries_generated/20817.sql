WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN U.Reputation IS NULL THEN 'Unknown' ELSE 'Known' END ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    WHERE U.CreationDate < (NOW() - INTERVAL '2 years') 
      AND (U.Location IS NOT NULL OR U.AboutMe IS NOT NULL)
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(COALESCE(P.Score, 0)) AS AvgScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
RecentEdits AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserId,
        PH.Comment,
        PH.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RecentEditRank
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) 
      AND PH.CreationDate > (NOW() - INTERVAL '30 days')
),
UserBadgeCount AS (
    SELECT 
        B.UserId, 
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM Badges B
    GROUP BY B.UserId
),
CombinedStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        COALESCE(PS.PostCount, 0) AS TotalPosts,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(UB.HighestBadgeClass, 0) AS HighestBadge
    FROM RankedUsers U
    LEFT JOIN PostStats PS ON U.UserId = PS.OwnerUserId
    LEFT JOIN UserBadgeCount UB ON U.UserId = UB.UserId
)
SELECT 
    C.*,
    COALESCE(RE.UserId, 'No recent edits') AS LastEditor,
    MAX(RE.Comment) AS LastComment
FROM CombinedStats C
LEFT JOIN RecentEdits RE ON C.UserId = RE.UserId AND RE.RecentEditRank = 1
GROUP BY 
    C.UserId, 
    C.DisplayName,
    C.TotalPosts,
    C.TotalViews,
    C.TotalScore,
    C.BadgeCount,
    C.HighestBadge
ORDER BY 
    C.TotalViews DESC, 
    C.TotalScore DESC NULLS LAST
LIMIT 100;
