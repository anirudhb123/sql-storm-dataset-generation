WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY P.Id) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY P.Id) AS Downvotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '1 month'
),

UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        AVG(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        AVG(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        AVG(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),

PostHistorySummary AS (
    SELECT 
        PH.PostId,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS HistoryTypes,
        COUNT(PH.Id) AS ChangeCount,
        MIN(PH.CreationDate) AS FirstChangeDate,
        MAX(PH.CreationDate) AS LastChangeDate
    FROM 
        PostHistory PH
    INNER JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)

SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    COALESCE(UP.PostId, NULL) AS LatestPostId,
    COALESCE(UP.Title, 'No Posts Yet') AS LatestPostTitle,
    COALESCE(UP.Upvotes, 0) AS LatestPostUpvotes,
    COALESCE(UP.Downvotes, 0) AS LatestPostDownvotes,
    PH.HistoryTypes,
    PH.ChangeCount,
    PH.FirstChangeDate,
    PH.LastChangeDate
FROM 
    Users U
LEFT JOIN 
    UserBadgeCounts UB ON U.Id = UB.UserId
LEFT JOIN 
    RankedPosts UP ON U.Id = UP.OwnerUserId AND UP.UserPostRank = 1
LEFT JOIN 
    PostHistorySummary PH ON PH.PostId = UP.PostId
WHERE 
    U.Reputation > 0
    AND (UP.ViewCount IS NULL OR UP.ViewCount > 10)
ORDER BY 
    U.Reputation DESC, 
    PH.ChangeCount DESC NULLS LAST
LIMIT 50;
