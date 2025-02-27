WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        P2.Id AS PostId,
        P2.Title,
        P2.ParentId,
        PH.Level + 1
    FROM 
        Posts P2
    INNER JOIN 
        RecursivePostHierarchy PH ON PH.PostId = P2.ParentId
),
UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        COALESCE(PH.Level, -1) AS HierarchyLevel,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(UG.CommentCount, 0) AS UserCommentCount,
        COALESCE(UG.VoteCount, 0) AS UserVoteCount,
        COALESCE(UG.Upvotes, 0) AS UserUpvotes,
        COALESCE(UG.Downvotes, 0) AS UserDownvotes
    FROM 
        Posts P
    LEFT JOIN 
        RecursivePostHierarchy PH ON P.Id = PH.PostId
    LEFT JOIN 
        UserEngagement UG ON P.OwnerUserId = UG.UserId
)
SELECT 
    PM.PostId,
    PM.Title,
    PM.ViewCount,
    PM.Score,
    PM.HierarchyLevel,
    PM.UserCommentCount,
    PM.UserVoteCount,
    PM.UserUpvotes,
    PM.UserDownvotes,
    DENSE_RANK() OVER (PARTITION BY PM.HierarchyLevel ORDER BY PM.Score DESC) AS RankWithinLevel,
    CASE 
        WHEN PM.UserUpvotes > PM.UserDownvotes THEN 'Positive'
        WHEN PM.UserUpvotes < PM.UserDownvotes THEN 'Negative'
        ELSE 'Neutral'
    END AS PostSentiment
FROM 
    PostMetrics PM
WHERE 
    PM.ViewCount > 50
ORDER BY 
    PM.HierarchyLevel, PM.Score DESC;
