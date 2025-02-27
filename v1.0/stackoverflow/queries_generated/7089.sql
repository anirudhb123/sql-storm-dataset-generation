WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
TopBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Date) AS LastBadgeDate
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
ActiveUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        UPS.TotalPosts,
        UPS.TotalQuestions,
        UPS.TotalAnswers,
        UPS.TotalViews,
        UPS.TotalScore,
        UPS.LastPostDate,
        TB.BadgeCount,
        TB.LastBadgeDate
    FROM 
        UserPostStats UPS
    JOIN 
        Users U ON UPS.UserId = U.Id
    LEFT JOIN 
        TopBadges TB ON U.Id = TB.UserId
    WHERE 
        UPS.TotalPosts > 0
),
FilteredUsers AS (
    SELECT 
        A.UserId,
        A.DisplayName,
        A.TotalPosts,
        A.TotalQuestions,
        A.TotalAnswers,
        A.TotalViews,
        A.TotalScore,
        A.LastPostDate,
        A.BadgeCount,
        A.LastBadgeDate
    FROM 
        ActiveUsers A
    WHERE 
        A.TotalScore > 1000
        AND A.LastPostDate > NOW() - INTERVAL '1 YEAR'
)
SELECT 
    COUNT(*) AS ActiveUserCount,
    AVG(TotalPosts) AS AvgTotalPosts,
    AVG(TotalQuestions) AS AvgTotalQuestions,
    AVG(TotalAnswers) AS AvgTotalAnswers,
    AVG(TotalViews) AS AvgTotalViews,
    AVG(TotalScore) AS AvgTotalScore,
    MAX(LastPostDate) AS LatestPostDate
FROM 
    FilteredUsers;
