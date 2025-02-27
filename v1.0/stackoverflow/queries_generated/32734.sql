WITH RECURSIVE UserBadgeHierarchy AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        B.Class,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        B.Class IN (1, 2) -- Only Gold and Silver badges
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS Owner,
        COUNT(C.ID) AS CommentCount,
        RANK() OVER (PARTITION BY U.Id ORDER BY P.CreationDate DESC) AS RecentRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        P.Id, U.DisplayName
),
TopBadgedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(B.Reputation) AS TotalReputation,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        B.Class IN (1, 2) 
    GROUP BY 
        U.Id
    HAVING 
        COUNT(DISTINCT B.Id) >= 3
),
FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.Owner,
        RP.CommentCount,
        U.BadgeCount
    FROM 
        RecentPosts RP
    JOIN 
        TopBadgedUsers U ON RP.Owner = U.DisplayName
    WHERE 
        RP.Score > 10 AND 
        RP.CommentCount > 5
)
SELECT 
    FP.Title,
    FP.CreationDate,
    FP.Score,
    FP.ViewCount,
    FP.Owner,
    FP.CommentCount,
    FP.BadgeCount,
    UBT.DisplayName AS BadgedUser
FROM 
    FilteredPosts FP
LEFT JOIN 
    UserBadgeHierarchy UBT ON FP.Owner = UBT.DisplayName
WHERE 
    UBT.BadgeRank = 1
ORDER BY 
    FP.Score DESC, 
    FP.CreationDate DESC
LIMIT 100;
