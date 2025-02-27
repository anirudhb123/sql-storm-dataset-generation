
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        GROUP_CONCAT(B.Name SEPARATOR ', ') AS BadgeNames
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        GROUP_CONCAT(DISTINCT T.TagName SEPARATOR ', ') AS Tags
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN (
        SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM (SELECT @row := @row + 1 AS n
              FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                    UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers,
              (SELECT @row := 0) r) numbers
        WHERE numbers.n <= CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) + 1
    ) T ON TRUE
    WHERE P.CreationDate > NOW() - INTERVAL 30 DAY
    GROUP BY P.Id, P.Title, P.CreationDate
),
PopularBadgedUsers AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        UB.BadgeCount,
        AB.PostId,
        AB.Title,
        AB.CommentCount,
        AB.UpvoteCount,
        AB.DownvoteCount,
        AB.Tags
    FROM UserBadges UB
    JOIN ActivePosts AB ON UB.BadgeCount > 2 
    ORDER BY UB.BadgeCount DESC, AB.UpvoteCount DESC
    LIMIT 10
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    PostId,
    Title AS PostTitle,
    CommentCount,
    UpvoteCount,
    DownvoteCount,
    Tags
FROM PopularBadgedUsers
ORDER BY BadgeCount DESC, UpvoteCount DESC;
