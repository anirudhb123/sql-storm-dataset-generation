
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        AVG(CASE WHEN P.PostTypeId = 1 THEN P.Score END) AS AvgQuestionScore,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalViews,
        QuestionCount,
        AnswerCount,
        AvgQuestionScore,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        @rownum := @rownum + 1 AS Rank
    FROM UserActivity, (SELECT @rownum := 0) r
    ORDER BY Reputation DESC, TotalViews DESC
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        @rn := IF(@prev_user = P.OwnerUserId, @rn + 1, 1) AS RN,
        @prev_user := P.OwnerUserId
    FROM Posts P, (SELECT @rn := 0, @prev_user := NULL) r
    WHERE P.CreationDate >= NOW() - INTERVAL 30 DAY
    ORDER BY P.CreationDate DESC
),
PostLinkStats AS (
    SELECT 
        PL.PostId,
        COUNT(PL.RelatedPostId) AS RelatedCount
    FROM PostLinks PL
    WHERE PL.CreationDate <= NOW() - INTERVAL 1 YEAR
    GROUP BY PL.PostId
)

SELECT
    AU.DisplayName,
    AU.Reputation,
    AU.TotalViews,
    AU.QuestionCount,
    AU.AnswerCount,
    AU.AvgQuestionScore,
    AU.GoldBadges,
    AU.SilverBadges,
    AU.BronzeBadges,
    R.Title AS LastPostTitle,
    R.CreationDate AS LastPostDate,
    COALESCE(PLS.RelatedCount, 0) AS TotalRelatedPosts
FROM ActiveUsers AU
LEFT JOIN RecentPosts R ON AU.UserId = R.OwnerUserId AND R.RN = 1
LEFT JOIN PostLinkStats PLS ON R.Id = PLS.PostId
WHERE 
    (AU.Reputation > 100 AND AU.QuestionCount > 0) OR
    (AU.Reputation < 50 AND AU.AnswerCount > 10)
ORDER BY AU.Rank
LIMIT 50;
