WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        R.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy R ON P.ParentId = R.PostId
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        MAX(PH.CreationDate) AS LastEdited,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY COUNT(CASE WHEN DATEDIFF(DAY, P.CreationDate, GETDATE()) < 30 THEN 1 END) DESC) AS RecentActivityRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.Title, P.OwnerUserId
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        B.Class AS BadgeClass,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, B.Class
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CommentCount,
    PS.VoteCount,
    PS.LastEdited,
    R.Level AS PostHierarchyLevel,
    U.DisplayName,
    U.Reputation,
    COALESCE(BadgeSummary.BadgeCount, 0) AS TotalBadges,
    CASE 
        WHEN PS.CommentCount IS NULL THEN 'No comments'
        ELSE CAST(PS.CommentCount AS VARCHAR) + ' comments'
    END AS CommentStatus
FROM 
    PostStats PS
JOIN 
    RecursivePostHierarchy R ON PS.PostId = R.PostId
JOIN 
    Users U ON PS.OwnerUserId = U.Id
LEFT JOIN (
    SELECT 
        U.Id AS UserId,
        SUM(BadgeCount) AS BadgeCount
    FROM 
        UserBadges U
    GROUP BY 
        U.Id
) AS BadgeSummary ON U.Id = BadgeSummary.UserId
WHERE 
    PS.RecentActivityRank <= 5
ORDER BY 
    PS.VoteCount DESC, PS.CommentCount DESC;
