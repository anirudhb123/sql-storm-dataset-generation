WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Views,
        AnswerCount,
        QuestionCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
)
SELECT 
    RU.DisplayName,
    RU.Reputation,
    RU.Views,
    RU.AnswerCount,
    RU.QuestionCount,
    RU.GoldBadges,
    RU.SilverBadges,
    RU.BronzeBadges,
    CONCAT('Rank: ', CAST(RU.ReputationRank AS VARCHAR)) AS Ranking
FROM RankedUsers RU
WHERE RU.AnswerCount > 5 
  AND RU.ReputationRank <= 100
  AND (RU.GoldBadges > 0 OR RU.SilverBadges > 0)
ORDER BY RU.Reputation DESC;

-- Additional Insight on Post History Changes
SELECT 
    PH.PostId,
    PH.UserDisplayName,
    P.Title,
    PH.CreationDate,
    PH.Comment,
    PT.Name AS PostHistoryType
FROM PostHistory PH
JOIN Posts P ON PH.PostId = P.Id
JOIN PostHistoryTypes PT ON PH.PostHistoryTypeId = PT.Id
WHERE PH.CreationDate > NOW() - INTERVAL '1 year'
  AND PT.Name NOT IN ('Post Deleted', 'Post Locked')
ORDER BY PH.CreationDate DESC
LIMIT 50;

-- Link Analysis of Related Posts
SELECT 
    PL.PostId,
    P.Title AS SourcePost,
    RP.Title AS RelatedPost,
    LT.Name AS LinkType
FROM PostLinks PL
JOIN Posts P ON PL.PostId = P.Id
JOIN Posts RP ON PL.RelatedPostId = RP.Id
JOIN LinkTypes LT ON PL.LinkTypeId = LT.Id
WHERE PL.CreationDate > NOW() - INTERVAL '1 month'
  AND LT.Name = 'Duplicate'
ORDER BY PL.CreationDate DESC;
