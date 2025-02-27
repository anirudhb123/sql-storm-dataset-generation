WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
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
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        COUNT(C) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.Score > 10
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.CreationDate, U.DisplayName
    ORDER BY 
        P.ViewCount DESC
    LIMIT 10
),
LastEditHistory AS (
    SELECT 
        PH.PostId,
        PH.UserDisplayName,
        PH.CreationDate AS EditDate,
        PT.Name AS PostTypeName
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        PHT.Name IN ('Edit Body', 'Edit Title')
    ORDER BY 
        PH.CreationDate DESC
    LIMIT 20
)
SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation,
    UBC.GoldBadges,
    UBC.SilverBadges,
    UBC.BronzeBadges,
    PP.Title AS PopularPostTitle,
    PP.ViewCount AS PostViewCount,
    PP.CommentCount,
    LEH.UserDisplayName AS LastEditor,
    LEH.EditDate,
    LEH.PostTypeName
FROM 
    Users U
JOIN 
    UserBadgeCounts UBC ON U.Id = UBC.UserId
JOIN 
    PopularPosts PP ON U.Id = PP.OwnerUserId
LEFT JOIN 
    LastEditHistory LEH ON PP.PostId = LEH.PostId
WHERE 
    U.Reputation > 1000 
ORDER BY 
    U.Reputation DESC, 
    PP.ViewCount DESC;
