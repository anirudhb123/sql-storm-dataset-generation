
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId IN (10, 12) THEN 1 ELSE 0 END) AS ClosedPosts,
        AVG(COALESCE(P.Score, 0)) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentActivity AS (
    SELECT 
        PH.UserId,
        PH.CreationDate,
        @row_number := IF(@prev_user_id = PH.UserId, @row_number + 1, 1) AS ActivityRank,
        @prev_user_id := PH.UserId
    FROM 
        PostHistory PH, 
        (SELECT @row_number := 0, @prev_user_id := 0) AS rn
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL 30 DAY
    ORDER BY 
        PH.UserId, PH.CreationDate DESC
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        GROUP_CONCAT(B.Name ORDER BY B.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    US.UserId,
    US.DisplayName,
    COALESCE(US.TotalPosts, 0) AS TotalPosts,
    COALESCE(US.QuestionCount, 0) AS QuestionCount,
    COALESCE(US.AnswerCount, 0) AS AnswerCount,
    COALESCE(US.ClosedPosts, 0) AS ClosedPosts,
    COALESCE(US.AvgScore, 0) AS AvgScore,
    CASE 
        WHEN RA.ActivityRank IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS ActivityStatus,
    UB.BadgeCount,
    UB.BadgeNames
FROM 
    UserStats US
LEFT JOIN 
    RecentActivity RA ON US.UserId = RA.UserId AND RA.ActivityRank = 1
LEFT JOIN 
    UserBadges UB ON US.UserId = UB.UserId
WHERE 
    US.Reputation > 1000
ORDER BY 
    US.Reputation DESC
LIMIT 100;
