WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        DisplayName,
        LOCALTIMESTAMP AS CheckDate
    FROM 
        Users
    WHERE 
        Reputation IS NOT NULL
    
    UNION ALL
    
    SELECT 
        U.Id,
        U.Reputation + 10 AS Reputation,
        U.CreationDate,
        U.DisplayName,
        LOCALTIMESTAMP AS CheckDate
    FROM 
        Users U
    JOIN 
        UserReputation UR ON UR.Id = U.Id
    WHERE 
        U.Reputation < 2000
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViews,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.OwnerUserId
),
BadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
FinalResults AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UR.Reputation, 0) AS Reputation,
        PS.PostCount,
        PS.CommentCount,
        PS.TotalScore,
        PS.AverageViews,
        BS.BadgeCount,
        BS.BadgeNames,
        CASE WHEN PS.LastPostDate IS NULL THEN 'No Posts' ELSE 'Has Posts' END AS PostStatus
    FROM 
        Users U
    LEFT JOIN 
        UserReputation UR ON U.Id = UR.Id
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN 
        BadgeStats BS ON U.Id = BS.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    CommentCount,
    TotalScore,
    AverageViews,
    BadgeCount,
    BadgeNames,
    PostStatus
FROM 
    FinalResults
WHERE 
    Reputation > 100
ORDER BY 
    Reputation DESC, 
    PostCount DESC
LIMIT 10;

