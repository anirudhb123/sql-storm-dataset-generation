WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CreationDate,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 AND P.Score > 10 AND P.ViewCount > 1000
    ORDER BY 
        P.Score DESC, P.ViewCount DESC
    LIMIT 10
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(PHT.Name, ', ') AS EditTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    P.PostId,
    P.Title,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CreationDate,
    P.OwnerDisplayName,
    PHS.EditCount,
    PHS.LastEditDate,
    PHS.EditTypes
FROM 
    UserBadges U
JOIN 
    PopularPosts P ON U.UserId = P.OwnerUserId
JOIN 
    PostHistoryStats PHS ON P.Id = PHS.PostId
ORDER BY 
    U.BadgeCount DESC, P.Score DESC;
