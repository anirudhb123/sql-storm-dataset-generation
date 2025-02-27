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
    GROUP BY U.Id
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
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, TotalViews DESC) AS Rank
    FROM UserActivity
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
),
PostLinkStats AS (
    SELECT 
        PL.PostId,
        COUNT(PL.RelatedPostId) AS RelatedCount
    FROM PostLinks PL
    WHERE PL.CreationDate <= NOW() - INTERVAL '1 year'
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

This SQL query showcases complex constructs including Common Table Expressions (CTEs), aggregate functions, window functions, and conditional logic with the inclusion of outer joins and filters based on intricate criteria. It retrieves selective user metrics while relating them to their recent posts and links while filtering based on diverse reputation and activity parameters.
