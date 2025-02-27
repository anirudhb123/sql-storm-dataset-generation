WITH RankedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS DownvoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
), UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
), PostHistoryAggregates AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5) -- Edits to Title and Body
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName,
    COALESCE(UBC.GoldBadges, 0) AS GoldBadges,
    COALESCE(UBC.SilverBadges, 0) AS SilverBadges,
    COALESCE(UBC.BronzeBadges, 0) AS BronzeBadges,
    RP.Id AS PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.UpvoteCount,
    RP.DownvoteCount,
    PHA.EditCount,
    PHA.LastEditDate
FROM 
    Users U
JOIN 
    RankedPosts RP ON U.Id = RP.OwnerUserId
LEFT JOIN 
    UserBadgeCounts UBC ON U.Id = UBC.UserId
LEFT JOIN 
    PostHistoryAggregates PHA ON RP.Id = PHA.PostId
WHERE 
    RP.UserPostRank <= 3 -- Top 3 recent posts per user
    AND (RP.CreationDate >= NOW() - INTERVAL '1 year' OR RP.Score > 10)
ORDER BY 
    U.Reputation DESC, RP.ViewCount DESC;
