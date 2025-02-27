WITH RecursiveTopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        0 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL

    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        Level + 1
    FROM 
        Users U
    JOIN 
        Votes V ON U.Id = V.UserId
    JOIN 
        Posts P ON V.PostId = P.Id
    WHERE 
        P.OwnerUserId IS NOT NULL
        AND Level < 5
),

UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
),

PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(CASE WHEN C.UserId IS NOT NULL THEN 1 END), 0) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.Id, U.DisplayName
),

ComplexAnalytics AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.Score,
        PD.OwnerDisplayName,
        PD.CommentCount,
        COALESCE(BadgeCounts.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(BadgeCounts.BadgeNames, 'None') AS UserBadges
    FROM 
        PostDetails PD
    LEFT JOIN 
        UserBadges BadgeCounts ON PD.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = BadgeCounts.UserId)
)

SELECT 
    R.Id AS UserId,
    R.DisplayName,
    R.Reputation,
    CA.PostId,
    CA.Title,
    CA.CreationDate,
    CA.Score,
    CA.CommentCount,
    CA.UserBadgeCount,
    CA.UserBadges,
    R.Level
FROM 
    RecursiveTopUsers R
JOIN 
    ComplexAnalytics CA ON R.DisplayName = CA.OwnerDisplayName
WHERE 
    R.Reputation > 1000
ORDER BY 
    R.Reputation DESC, 
    CA.Score DESC
LIMIT 50;
