WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges,
        SUM(CASE WHEN B.TagBased = 1 THEN 1 ELSE 0 END) AS TagBasedCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) FILTER (WHERE P.PostTypeId = 1) AS QuestionCount,
        COUNT(*) FILTER (WHERE P.PostTypeId = 2) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.OwnerUserId IS NOT NULL
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PS.QuestionCount, 0) AS TotalQuestions,
    COALESCE(PS.AnswerCount, 0) AS TotalAnswers,
    COALESCE(PS.TotalViews, 0) AS TotalProfileViews,
    (CASE
        WHEN COALESCE(PS.AverageScore, 0) > 10 THEN 'High Score'
        ELSE 'Low Score'
    END) AS ScoreCategory,
    (SELECT STRING_AGG(RP.Title, ', ') 
     FROM RecentPosts RP 
     WHERE RP.OwnerUserId = U.Id AND RP.PostRank <= 3) AS RecentPostTitles
FROM Users U
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
WHERE (COALESCE(UB.GoldBadges, 0) + COALESCE(UB.SilverBadges, 0) + COALESCE(UB.BronzeBadges, 0)) > 0
ORDER BY TotalProfileViews DESC, UserId;
