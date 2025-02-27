WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id 
    WHERE 
        P.CreationDate >= DATEADD(year, -1, GETDATE()) 
        AND P.Score IS NOT NULL
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        Reputation 
    FROM 
        RankedPosts 
    WHERE 
        PostRank <= 5
),
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RP.Score,
        COUNT(C.Id) AS CommentCount,
        MAX(H.CreationDate) AS LastEditDate
    FROM 
        TopRankedPosts RP
    LEFT JOIN 
        Comments C ON RP.PostId = C.PostId
    LEFT JOIN 
        PostHistory H ON RP.PostId = H.PostId AND H.PostHistoryTypeId IN (4, 5)
    GROUP BY 
        RP.PostId, RP.Title, RP.ViewCount, RP.Score
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
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
    PD.PostId,
    PD.Title,
    PD.ViewCount,
    PD.Score,
    PD.CommentCount,
    PD.LastEditDate,
    UB.UserId,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    COALESCE((SELECT STRING_AGG(DISTINCT T.TagName, ', ') 
               FROM Tags T 
               JOIN STRING_SPLIT(P.Tags, ',') AS ST ON T.TagName = ST.value), 'No Tags') AS AssociatedTags
FROM 
    PostDetails PD
JOIN 
    Posts P ON PD.PostId = P.Id
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
WHERE 
    PD.Score > 10 AND 
    PD.ViewCount > 1000
ORDER BY 
    PD.Score DESC, PD.ViewCount DESC;
