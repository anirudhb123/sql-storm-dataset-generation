
WITH UserBadgeCounts AS (
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
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        UBC.BadgeCount,
        UBC.GoldBadges,
        UBC.SilverBadges,
        UBC.BronzeBadges,
        @rank := @rank + 1 AS Rank
    FROM 
        Users U
    JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId,
        (SELECT @rank := 0) r
    WHERE 
        U.Reputation > 1000
    ORDER BY 
        U.Reputation DESC, UBC.BadgeCount DESC
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.CreationDate,
        @postRank := @postRank + 1 AS PostRank
    FROM 
        Posts P,
        (SELECT @postRank := 0) r
    WHERE 
        P.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL 1 YEAR
        AND P.PostTypeId = 1
    ORDER BY 
        P.ViewCount DESC, P.Score DESC
),
CombinedData AS (
    SELECT 
        TU.DisplayName,
        TU.Reputation,
        TU.GoldBadges,
        TU.SilverBadges,
        TU.BronzeBadges,
        PP.Title,
        PP.Score,
        PP.ViewCount,
        PP.AnswerCount,
        PP.CommentCount,
        PP.CreationDate
    FROM 
        TopUsers TU
    JOIN 
        PopularPosts PP ON TU.Rank <= 10
)
SELECT 
    DisplayName,
    Reputation,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    Title,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    CreationDate
FROM 
    CombinedData
ORDER BY 
    Reputation DESC, Score DESC;
