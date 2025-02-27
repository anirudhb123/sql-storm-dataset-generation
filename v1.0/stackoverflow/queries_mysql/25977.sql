
WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),

TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CreationDate,
        P.OwnerUserId,
        @row_num := @row_num + 1 AS Rank
    FROM Posts P, (SELECT @row_num := 0) r
    WHERE P.PostTypeId = 1  
    ORDER BY P.Score DESC, P.ViewCount DESC
),

TagAnalysis AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts P
    INNER JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
                UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
    WHERE P.PostTypeId = 1
    GROUP BY TagName
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.BadgeCount,
    U.GoldBadgeCount,
    U.SilverBadgeCount,
    U.BronzeBadgeCount,
    TP.PostId,
    TP.Title AS TopPostTitle,
    TP.Score AS TopPostScore,
    TP.ViewCount AS TopPostViewCount,
    TP.AnswerCount AS TopPostAnswerCount,
    TP.CreationDate AS TopPostCreationDate,
    TA.TagName,
    TA.PostCount AS TagPopularity
FROM UserBadgeCounts U
JOIN TopPosts TP ON U.UserId = TP.OwnerUserId
JOIN TagAnalysis TA ON TA.PostCount > 5 
WHERE TP.Rank <= 10 
ORDER BY U.BadgeCount DESC, TP.Score DESC;
