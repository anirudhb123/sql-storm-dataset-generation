
WITH TagCounts AS (
    SELECT 
        TRIM(REPLACE(tag, '<', '')) AS TagName, 
        COUNT(*) AS Count
    FROM (
        SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS tag
        FROM Posts
        JOIN (
            SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
        WHERE PostTypeId = 1
    ) AS TagsList
    GROUP BY TagName
), UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
), BadgeSummary AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
)
SELECT 
    UA.UserId, 
    UA.DisplayName,
    UA.PostCount, 
    UA.AnswerCount,
    UA.QuestionCount,
    BS.GoldBadges,
    BS.SilverBadges,
    BS.BronzeBadges,
    TC.TagName,
    TC.Count AS TagUsageCount
FROM UserActivity UA
JOIN BadgeSummary BS ON UA.UserId = BS.UserId
JOIN TagCounts TC ON UA.UserId IN (SELECT OwnerUserId FROM Posts WHERE Tags LIKE CONCAT('%', TC.TagName, '%'))
ORDER BY UA.PostCount DESC, TagUsageCount DESC
LIMIT 10;
