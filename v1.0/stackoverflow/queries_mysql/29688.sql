
WITH TagsSplit AS (
    SELECT 
        Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1  
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagCount
    FROM 
        TagsSplit 
    GROUP BY 
        Tag 
    ORDER BY 
        TagCount DESC 
    LIMIT 10
),
QuestionAnalytics AS (
    SELECT 
        P.Title,
        P.ViewCount,
        P.Score,
        T.Tag,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        UR.BadgeCount
    FROM 
        Posts P
    JOIN 
        TagsSplit T ON P.Id = T.PostId
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    JOIN 
        UserReputation UR ON U.Id = UR.UserId
    WHERE 
        T.Tag IN (SELECT Tag FROM PopularTags)
    ORDER BY 
        P.ViewCount DESC
)
SELECT 
    * 
FROM 
    QuestionAnalytics
LIMIT 20;
