
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.Tags,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank,
        P.OwnerUserId
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR AND 
        P.Score > 0
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 AS n
         FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
               SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
               SELECT 8 UNION ALL SELECT 9) a,
              (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
               SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
               SELECT 8 UNION ALL SELECT 9) b) n
    WHERE 
        n.n <= 10
    GROUP BY 
        TagName
    HAVING 
        CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.OwnerDisplayName,
    RP.CreationDate,
    RP.Score,
    PT.TagName,
    UB.UserId,
    UB.BadgeCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges
FROM 
    RankedPosts RP
JOIN 
    PopularTags PT ON RP.Tags LIKE CONCAT('%', PT.TagName, '%')
JOIN 
    UserBadges UB ON RP.OwnerUserId = UB.UserId
WHERE 
    RP.PostRank <= 5
ORDER BY 
    RP.Score DESC, 
    UB.BadgeCount DESC, 
    RP.CreationDate DESC;
