WITH UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(B.Id) AS BadgeCount, 
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,  -- assuming id 2 = UpMod
        SUM(V.VoteTypeId = 3) AS DownVotes,  -- assuming id 3 = DownMod
        SUM(V.VoteTypeId = 10) AS DeletionVotes, -- assuming id 10 = Deletion
        SUM(V.VoteTypeId = 11) AS UndeletionVotes -- assuming id 11 = Undeletion
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.OwnerUserId
),
PostRanked AS (
    SELECT 
        PS.PostId,
        PS.OwnerUserId,
        PS.CommentCount,
        PS.UpVotes,
        PS.DownVotes,
        PS.DeletionVotes,
        PS.UndeletionVotes,
        RANK() OVER (PARTITION BY PS.OwnerUserId ORDER BY PS.UpVotes DESC, PS.DownVotes ASC) AS RankPosition
    FROM 
        PostSummary PS
)
SELECT 
    U.DisplayName AS UserName,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    COALESCE(UB.GoldBadgeCount, 0) AS GoldBadges,
    COALESCE(UB.SilverBadgeCount, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadgeCount, 0) AS BronzeBadges,
    SUM(CASE WHEN PR.RankPosition = 1 THEN 1 ELSE 0 END) AS TopPosts,
    SUM(PR.CommentCount) AS TotalComments,
    SUM(PR.UpVotes) AS TotalUpVotes,
    SUM(PR.DownVotes) AS TotalDownVotes,
    SUM(PR.DeletionVotes) AS TotalDeletionVotes,
    SUM(PR.UndeletionVotes) AS TotalUndeletionVotes
FROM 
    Users U
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    PostRanked PR ON U.Id = PR.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName
HAVING 
    COUNT(PR.PostId) > 0
ORDER BY 
    TotalUpVotes DESC, TotalComments DESC
LIMIT 10;

WITH RECURSIVE PostHierarchy AS (
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
        P.Id, 
        P.Title, 
        P.ParentId, 
        H.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        PostHierarchy H ON P.ParentId = H.PostId
)
SELECT 
    PH.PostId, 
    PH.Title, 
    PH.Level,
    COALESCE(PH.ParentId, -1) AS Parent
FROM 
    PostHierarchy PH
WHERE 
    PH.Level > 1
ORDER BY 
    PH.Level, PH.Title;
