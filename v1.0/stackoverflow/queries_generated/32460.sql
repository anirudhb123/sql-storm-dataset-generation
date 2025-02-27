WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL  -- Starting from top-level Posts (Questions)
    
    UNION ALL
    
    SELECT 
        P.Id,
        P.Title,
        P.ParentId,
        Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy RPH ON P.ParentId = RPH.PostId
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.PostTypeId,
        COALESCE(CAST(SUM(V.VoteTypeId = 2) AS INT), 0) AS UpVotes,  -- Count of Upvotes
        COALESCE(CAST(SUM(V.VoteTypeId = 3) AS INT), 0) AS DownVotes,  -- Count of Downvotes
        COALESCE(CAST(SUM(V.VoteTypeId = 4) AS INT), 0) AS OffensiveVotes,  -- Count of Offensive votes
        CASE 
            WHEN COUNT(CASE WHEN V.VoteTypeId = 6 THEN 1 END) > 0 THEN 'Closed'
            ELSE 'Open' 
        END AS PostStatus
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId 
    GROUP BY 
        P.Id
),
UsersWithBadges AS (
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
        U.Id
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.UpVotes,
    PS.DownVotes,
    PS.OffensiveVotes,
    PS.PostStatus,
    UWB.DisplayName AS PostOwner,
    UWB.BadgeCount,
    UWB.GoldBadges,
    UWB.SilverBadges,
    UWB.BronzeBadges,
    RPH.Level AS PostLevel
FROM 
    PostStats PS
JOIN 
    UsersWithBadges UWB ON PS.OwnerUserId = UWB.UserId
LEFT JOIN 
    RecursivePostHierarchy RPH ON PS.PostId = RPH.PostId
WHERE 
    PS.PostTypeId = 1  -- Only questions
    AND (PS.UpVotes - PS.DownVotes) > 10  -- Popularity filter
ORDER BY 
    PS.UpVotes DESC, 
    PS.DownVotes ASC, 
    UWB.BadgeCount DESC;
