
WITH TagsSplit AS (
    SELECT 
        Id AS PostId,
        value AS Tag
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
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
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
ORDER BY 
    (SELECT NULL)
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
