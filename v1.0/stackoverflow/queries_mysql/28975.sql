
WITH UserBadgeCounts AS (
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
), 
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT T.TagName SEPARATOR ', ') AS Tags
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN (SELECT TRIM(BOTH ' ' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', numbers.n), ',', -1)) AS Tag
               FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
                     UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
                     UNION ALL SELECT 10) numbers
               WHERE CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, ',', '')) >= numbers.n - 1) AS Tag ON TRUE
    LEFT JOIN Tags T ON Tag.Tag = T.TagName
    WHERE P.CreationDate > DATE_SUB('2024-10-01', INTERVAL 1 YEAR)
    GROUP BY P.Id, P.Title, P.ViewCount, P.Score
    ORDER BY P.ViewCount DESC 
    LIMIT 10
)
SELECT 
    UBC.DisplayName,
    UBC.BadgeCount,
    UBC.GoldBadges,
    UBC.SilverBadges,
    UBC.BronzeBadges,
    PP.Title AS PopularPostTitle,
    PP.ViewCount AS PopularPostViewCount,
    PP.Score AS PopularPostScore,
    PP.CommentCount AS PopularPostCommentCount,
    PP.Tags AS PopularPostTags
FROM UserBadgeCounts UBC
JOIN PopularPosts PP ON UBC.UserId IN (
    SELECT DISTINCT P.OwnerUserId
    FROM Posts P 
    WHERE P.Title = PP.Title
)
ORDER BY UBC.BadgeCount DESC, PP.ViewCount DESC;
