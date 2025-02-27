WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL

    UNION ALL

    SELECT 
        C.Id AS PostId,
        C.Title,
        C.ParentId,
        R.Level + 1
    FROM 
        Posts C
    INNER JOIN 
        RecursivePostHierarchy R ON C.ParentId = R.PostId
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        COALESCE(NULLIF(U.Location, ''), 'Not specified') AS UserLocation,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpvoteCount,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostOrder
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
FilteredPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.ViewCount,
        PS.Score,
        PS.CommentCount,
        CASE 
            WHEN PS.Score >= 0 THEN 'Non-negative' 
            ELSE 'Negative' 
        END AS ScoreCategory
    FROM 
        PostStatistics PS
    WHERE 
        PS.CommentCount > 5
)
SELECT 
    RPH.PostId,
    RPH.Title AS PostTitle,
    F.Title AS ParentTitle,
    RPH.Level,
    UR.DisplayName AS UserName,
    UR.Reputation AS UserReputation,
    UR.UserLocation,
    FP.ViewCount,
    FP.Score AS PostScore,
    FP.CommentCount,
    FP.ScoreCategory,
    FP.CreationDate,
    (SELECT STRING_AGG(T.TagName, ', ') 
     FROM Tags T 
     JOIN Posts P ON P.Tags::text LIKE '%' || T.TagName || '%'
     WHERE P.Id = RPH.PostId) AS AssociatedTags
FROM 
    RecursivePostHierarchy RPH
LEFT JOIN 
    Posts F ON RPH.ParentId = F.Id
LEFT JOIN 
    Users UR ON RPH.PostId IN (SELECT OwnerUserId FROM Posts WHERE Id = RPH.PostId)
LEFT JOIN 
    FilteredPosts FP ON FP.PostId = RPH.PostId
WHERE 
    RPH.Level <= 2
ORDER BY 
    RPH.Level, UR.Reputation DESC;
