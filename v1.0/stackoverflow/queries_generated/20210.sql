WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AvgScore,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVotes,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(PS.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(PS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(PS.AvgScore, 0) AS AvgScore,
        COALESCE(PS.UpVotes, 0) AS UpVotes,
        COALESCE(PS.DownVotes, 0) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeCounts UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
),
FinalResults AS (
    SELECT 
        *,
        (TotalQuestions + TotalAnswers) * (BadgeCount + 1) AS PerformanceScore
    FROM 
        UserPerformance
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    AvgScore,
    UpVotes,
    DownVotes,
    PerformanceScore,
    CASE 
        WHEN PerformanceScore > 100 THEN 'High Performer'
        WHEN PerformanceScore BETWEEN 50 AND 100 THEN 'Average Performer'
        ELSE 'Low Performer'
    END AS PerformanceCategory
FROM 
    FinalResults
WHERE 
    TotalPosts > 0
ORDER BY 
    PerformanceScore DESC, TotalPosts DESC
LIMIT 10;
