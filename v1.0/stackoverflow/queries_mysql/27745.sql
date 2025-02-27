
WITH TagFrequency AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS Frequency
    FROM Posts
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE PostTypeId = 1 
    GROUP BY Tag
), UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
), TopTags AS (
    SELECT 
        Tag,
        Frequency,
        @tagRank := @tagRank + 1 AS TagRank
    FROM TagFrequency, (SELECT @tagRank := 0) r
    ORDER BY Frequency DESC
), TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        BadgeCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        @userRank := @userRank + 1 AS UserRank
    FROM UserBadges, (SELECT @userRank := 0) r
)
SELECT 
    T.Tag, 
    T.Frequency, 
    U.DisplayName AS TopUser, 
    U.BadgeCount, 
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges
FROM TopTags T
JOIN TopUsers U ON U.UserRank = 1
WHERE T.TagRank <= 10 
ORDER BY T.Frequency DESC, U.BadgeCount DESC;
