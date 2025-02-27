
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        GROUP_CONCAT(DISTINCT T.TagName) AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1)) AS TagName
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
          SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
          SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1) AS T ON TRUE
    WHERE 
        P.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadgeCount,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadgeCount,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.CreationDate,
    PS.CommentCount,
    PS.UpVoteCount,
    PS.DownVoteCount,
    PS.Tags,
    UB.UserId,
    UB.GoldBadgeCount,
    UB.SilverBadgeCount,
    UB.BronzeBadgeCount
FROM 
    PostStats PS
JOIN 
    Users U ON U.Id = PS.PostId
JOIN 
    UserBadges UB ON U.Id = UB.UserId
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC
LIMIT 100;
