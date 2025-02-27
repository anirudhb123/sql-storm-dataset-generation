WITH UserBadgeCount AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UBC.BadgeCount, 0) AS TotalBadges,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.AvgViewCount, 0) AS AvgViewCount
    FROM Users U
    LEFT JOIN UserBadgeCount UBC ON U.Id = UBC.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TotalBadges,
    U.QuestionCount,
    U.AnswerCount,
    U.TotalScore,
    U.AvgViewCount,
    RANK() OVER (ORDER BY U.TotalScore DESC) AS ScoreRank,
    NTILE(4) OVER (ORDER BY U.AvgViewCount DESC) AS ViewCountQuartile,
    CASE 
        WHEN U.TotalBadges > 10 THEN 'Highly Recognized'
        WHEN U.TotalBadges BETWEEN 5 AND 10 THEN 'Moderately Recognized'
        ELSE 'New User'
    END AS RecognitionLevel,
    (
        SELECT STRING_AGG(DISTINCT T.TagName, ', ')
        FROM Posts P
        JOIN STRING_TO_ARRAY(P.Tags, '>,<') AS TagArray ON P.Tags = (SELECT ARRAY_AGG(DISTINCT T.TagName) FROM Tags T WHERE T.Id IN (SELECT UNNEST(TagArray)))
        WHERE P.OwnerUserId = U.UserId
    ) AS PopularTags
FROM UserPostStats U
WHERE U.TotalScore > (
    SELECT AVG(TotalScore) FROM UserPostStats
)
ORDER BY U.TotalScore DESC
FETCH FIRST 10 ROWS ONLY;
