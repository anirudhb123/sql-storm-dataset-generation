WITH UserBadges AS (
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
PostMetrics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - P.CreationDate)) / 3600) AS AvgPostAgeInHours,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PM.PostCount, 0) AS PostCount,
        COALESCE(PM.TotalScore, 0) AS TotalScore,
        COALESCE(PM.AvgPostAgeInHours, 0) AS AvgPostAgeInHours,
        COALESCE(PM.QuestionCount, 0) AS QuestionCount,
        COALESCE(PM.AnswerCount, 0) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostMetrics PM ON U.Id = PM.OwnerUserId
),
UserRankedActivity AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.BadgeCount,
        UA.PostCount,
        UA.TotalScore,
        UA.AvgPostAgeInHours,
        UA.QuestionCount,
        UA.AnswerCount,
        RANK() OVER (PARTITION BY CASE WHEN UA.Reputation >= 1000 THEN 'High' ELSE 'Low' END ORDER BY UA.TotalScore DESC) AS ScoreRank
    FROM 
        UserActivity UA
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.PostCount,
    U.TotalScore,
    (U.QuestionCount - U.AnswerCount) AS QuestionToAnswerRatio,
    U.AvgPostAgeInHours,
    CASE WHEN U.ScoreRank IS NULL THEN 'Unranked' ELSE CAST(U.ScoreRank AS VARCHAR) END AS ScoreRank,
    CASE 
        WHEN U.BadgeCount > 10 THEN 'Veteran'
        WHEN U.BadgeCount BETWEEN 5 AND 10 THEN 'Experienced'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    UserRankedActivity U
WHERE 
    U.PostCount > (SELECT AVG(PostCount) FROM UserActivity)
ORDER BY 
    U.TotalScore DESC, 
    U.BadgeCount DESC
FETCH FIRST 100 ROWS ONLY;
