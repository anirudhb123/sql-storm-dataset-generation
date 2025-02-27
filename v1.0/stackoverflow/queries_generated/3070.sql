WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionsCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswersCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
PostHistoryAggregates AS (
    SELECT 
        PostId,
        MAX(CASE WHEN PHT.PostHistoryTypeId = 10 THEN PH.CreationDate END) AS ClosuredDate,
        COUNT(CASE WHEN PH.UserId IS NOT NULL THEN 1 END) AS EditCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PostId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(PS.TotalPosts, 0) AS TotalPosts,
    COALESCE(PS.AverageScore, 0) AS AverageScore,
    COALESCE(PS.TotalViews, 0) AS TotalViews,
    COALESCE(PH.EditCount, 0) AS EditCount,
    PH.ClosuredDate,
    CASE 
        WHEN COALESCE(UB.BadgeCount, 0) = 0 THEN 'No Badges'
        ELSE 'Has Badges'
    END AS BadgeStatus
FROM 
    Users U
LEFT JOIN 
    UserBadgeCounts UB ON U.Id = UB.UserId
LEFT JOIN 
    PostStatistics PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    PostHistoryAggregates PH ON U.Id = (SELECT OwnerUserId FROM Posts WHERE Id = PH.PostId LIMIT 1)
WHERE 
    (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = U.Id) > 5
ORDER BY 
    TotalViews DESC, AverageScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
