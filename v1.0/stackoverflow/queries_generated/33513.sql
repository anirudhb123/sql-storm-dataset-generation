WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        P.Title,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL
    UNION ALL
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        P.Title,
        RPH.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy RPH ON P.ParentId = RPH.PostId
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges
    FROM 
        Users U
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(COUNT(DISTINCT C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.CreationDate IS NOT NULL), 0) AS UpvoteCount,
        COALESCE(SUM(V.UserId IS NOT NULL AND V.VoteTypeId = 3), 0) AS DownvoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 3)
    GROUP BY 
        P.Id
),
TopEngagedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        UE.CommentCount,
        UE.VoteCount,
        RANK() OVER (ORDER BY UE.VoteCount DESC, UE.CommentCount DESC) AS EngagementRank
    FROM 
        Users U
    JOIN 
        UserEngagement UE ON U.Id = UE.UserId
    WHERE 
        U.Reputation > 1000
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.ViewCount,
    PS.Score,
    PS.CommentCount,
    PS.UpvoteCount,
    PS.DownvoteCount,
    PU.DisplayName AS TopEngagedUser,
    PU.CommentCount AS UserCommentCount,
    PU.VoteCount AS UserVoteCount
FROM 
    PostStats PS
LEFT JOIN 
    (SELECT 
         PostId, 
         ROW_NUMBER() OVER (PARTITION BY PostId ORDER BY EngagementRank) AS rn, 
         UserId, 
         DisplayName, 
         CommentCount, 
         VoteCount
     FROM 
         TopEngagedUsers) PU ON PS.PostId = PU.PostId AND PU.rn = 1
WHERE 
    PS.ViewCount > 50
ORDER BY 
    PS.ViewCount DESC, 
    PS.Score DESC;
