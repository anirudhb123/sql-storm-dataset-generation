WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        P.ClosedDate,
        P.Body,
        ROW_NUMBER() OVER (PARTITION BY Tags ORDER BY P.Score DESC) AS RN
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
        AND P.Score > 0
        AND P.ClosedDate IS NULL
        AND P.Title IS NOT NULL 
    CROSS JOIN LATERAL (
        SELECT 
            STRING_AGG(T.TagName, ', ') AS Tags
        FROM 
            Tags T
        WHERE
            T.Id = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '>')::int[])
    ) AS TTags
),
UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        COUNT(B.Id) AS TotalBadges,
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
PostHistoryAgg AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseOpenCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 12 THEN 1 END) AS DeletedCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 24 THEN 1 END) AS EditedCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    COALESCE(UB.TotalBadges, 0) AS UserBadgeCount,
    COALESCE(PHA.CloseOpenCount, 0) AS PostCloseOpenCount,
    COALESCE(PHA.DeletedCount, 0) AS PostDeletedCount,
    COALESCE(PHA.EditedCount, 0) AS PostEditedCount,
    RP.CreationDate,
    RP.ViewCount,
    RP.AnswerCount,
    RP.Body
FROM 
    RankedPosts RP
LEFT JOIN 
    Users U ON U.Id = RP.OwnerUserId
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    PostHistoryAgg PHA ON RP.PostId = PHA.PostId
WHERE 
    RP.RN <= 10
ORDER BY 
    RP.Score DESC,
    RP.ViewCount DESC
LIMIT 100;
