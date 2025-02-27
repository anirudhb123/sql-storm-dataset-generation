WITH RecursiveUserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        1 AS UserLevel
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1  -- Only Questions
    UNION ALL
    SELECT 
        U.Id,
        U.DisplayName,
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        RU.UserLevel + 1
    FROM 
        RecursiveUserPosts RU
    JOIN 
        Posts P ON P.ParentId = RU.PostId
    JOIN 
        Users U ON P.OwnerUserId = U.Id
)
, BadgeUserStats AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    RU.DisplayName,
    RU.Title,
    RU.CreationDate,
    RU.Score,
    RU.ViewCount,
    RU.AnswerCount,
    RU.CommentCount,
    BS.GoldBadges,
    BS.SilverBadges,
    BS.BronzeBadges
FROM 
    RecursiveUserPosts RU
JOIN 
    BadgeUserStats BS ON RU.UserId = BS.UserId
WHERE 
    RU.ViewCount > (
        SELECT 
            AVG(ViewCount) 
            FROM Posts 
            WHERE PostTypeId = 1
    )
AND 
    RU.UserLevel <= 2  -- Limiting to two levels deep
ORDER BY 
    RU.Score DESC, RU.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
