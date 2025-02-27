
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Date) AS LastBadgeDate
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
), 
PostActivity AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        COALESCE(AVG(P.Score), 0) AS AverageScore,
        MAX(P.LastActivityDate) AS LastPostActivity
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.CreationDate > CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(MONTH, -6, GETDATE()) OR PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        P.OwnerUserId
), 
UserPerformance AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        UB.BadgeCount,
        PA.PostCount,
        PA.TotalViews,
        PA.AverageScore,
        CASE 
            WHEN PA.LastPostActivity IS NULL THEN NULL 
            ELSE DATEDIFF(DAY, PA.LastPostActivity, CAST('2024-10-01 12:34:56' AS DATETIME)) 
        END AS DaysSinceLastPost
    FROM 
        UserBadges UB
    LEFT JOIN 
        PostActivity PA ON UB.UserId = PA.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.BadgeCount,
    U.PostCount,
    U.TotalViews,
    U.AverageScore,
    U.DaysSinceLastPost,
    CASE 
        WHEN U.PostCount > 50 THEN 'Active Contributor'
        WHEN U.BadgeCount > 10 THEN 'Badge Collector'
        ELSE 'Newcomer'
    END AS UserType,
    COALESCE(
        (SELECT 
             COUNT(*) 
         FROM 
             Votes V 
         WHERE 
             V.UserId = U.UserId AND V.VoteTypeId = 2), 0
    ) AS UpvotesGiven,
    COALESCE(
        (SELECT 
             COUNT(*) 
         FROM 
             Comments C 
         WHERE 
             C.UserId = U.UserId), 0
    ) AS CommentsMade
FROM 
    UserPerformance U 
WHERE 
    U.PostCount > 0 
    AND U.BadgeCount IS NOT NULL
    AND U.DaysSinceLastPost < 30 
ORDER BY 
    U.AverageScore DESC 
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY; 
