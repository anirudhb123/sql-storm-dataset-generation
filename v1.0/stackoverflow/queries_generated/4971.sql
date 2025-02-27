WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        AVG(COALESCE(P.Score, 0)) AS AvgScore,
        AVG(COALESCE(P.ViewCount, 0)) AS AvgViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
), BadgedUsers AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS MaxBadgeClass
    FROM 
        Badges B
    GROUP BY 
        B.UserId
), UserReputation AS (
    SELECT 
        U.Id,
        U.Reputation,
        CASE 
            WHEN RANK() OVER (ORDER BY U.Reputation DESC) <= 10 THEN 'Top 10 Users'
            ELSE 'Regular Users'
        END AS UserRank
    FROM 
        Users U
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalAnswers,
    UPS.TotalQuestions,
    UPS.AvgScore,
    UPS.AvgViews,
    COALESCE(BU.BadgeCount, 0) AS BadgeCount,
    COALESCE(BU.MaxBadgeClass, 0) AS MaxBadgeClass,
    UR.UserRank
FROM 
    UserPostStats UPS
LEFT JOIN 
    BadgedUsers BU ON UPS.UserId = BU.UserId
JOIN 
    UserReputation UR ON UPS.UserId = UR.Id
WHERE 
    UPS.TotalPosts > 5
    AND UR.Reputation > 100
ORDER BY 
    UPS.TotalPosts DESC, UPS.AvgScore DESC
LIMIT 50

UNION ALL

SELECT 
    NULL AS UserId,
    'Average' AS DisplayName,
    COUNT(*) AS TotalPosts,
    AVG(TotalAnswers) AS TotalAnswers,
    AVG(TotalQuestions) AS TotalQuestions,
    AVG(AvgScore) AS AvgScore,
    AVG(AvgViews) AS AvgViews,
    AVG(BadgeCount) AS BadgeCount,
    AVG(MaxBadgeClass) AS MaxBadgeClass,
    NULL AS UserRank
FROM 
    (
        SELECT 
            UPS.TotalPosts,
            UPS.TotalAnswers,
            UPS.TotalQuestions,
            UPS.AvgScore,
            UPS.AvgViews,
            COALESCE(BU.BadgeCount, 0) AS BadgeCount,
            COALESCE(BU.MaxBadgeClass, 0) AS MaxBadgeClass
        FROM 
            UserPostStats UPS
        LEFT JOIN 
            BadgedUsers BU ON UPS.UserId = BU.UserId
        JOIN 
            UserReputation UR ON UPS.UserId = UR.Id
        WHERE 
            UPS.TotalPosts > 5
            AND UR.Reputation > 100
    ) AS Stats;
