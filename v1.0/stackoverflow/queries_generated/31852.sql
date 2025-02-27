WITH RECURSIVE PostTree AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Select only Questions to start
    
    UNION ALL
    
    SELECT 
        P.Id,
        P.Title,
        P.ParentId,
        PT.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        PostTree PT ON P.ParentId = PT.PostId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        PT.Level AS TreeLevel,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        COUNT(DISTINCT PH.UserId) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        PostHistory PH ON PH.PostId = P.Id
    LEFT JOIN 
        PostTree PT ON P.Id = PT.PostId
    GROUP BY 
        P.Id, P.OwnerUserId, P.Score, P.ViewCount, PT.Level
)
SELECT 
    PM.PostId,
    PM.Score,
    PM.ViewCount,
    PM.TotalComments,
    PM.TreeLevel,
    US.DisplayName,
    US.Reputation,
    US.Upvotes,
    US.Downvotes,
    CASE 
        WHEN PM.AcceptedAnswerId = -1 THEN 'No accepted answer'
        ELSE 'Has accepted answer'
    END AS AcceptedAnswerStatus,
    COALESCE(PM.LastEditDate, 'Never Edited') AS LastEditDate,
    CASE 
        WHEN PM.TreeLevel > 1 THEN 'This post is part of a thread'
        ELSE 'Stand-alone post'
    END AS PostThreadStatus
FROM 
    PostMetrics PM
LEFT JOIN 
    UserStats US ON PM.OwnerUserId = US.UserId
ORDER BY 
    PM.Score DESC, PM.ViewCount DESC;
