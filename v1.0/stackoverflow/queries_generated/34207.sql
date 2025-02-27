WITH RECURSIVE PostHierarchy AS (
    SELECT P.Id AS PostId, P.Title, P.ParentId, P.CreationDate, 1 AS Level
    FROM Posts P
    WHERE P.ParentId IS NULL
    
    UNION ALL
    
    SELECT P.Id AS PostId, P.Title, P.ParentId, P.CreationDate, PH.Level + 1
    FROM Posts P
    INNER JOIN PostHierarchy PH ON P.ParentId = PH.PostId
),
PostVoteSummary AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(V.Id) AS TotalVotes,
        COALESCE(PH.Level, 0) AS PostLevel
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN PostHierarchy PH ON P.Id = PH.PostId
    GROUP BY P.Id, PH.Level
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        PH.PostLevel,
        CASE 
            WHEN PH.Level = 0 THEN 'Root Post'
            WHEN PH.Level = 1 THEN 'Child Post'
            ELSE 'Nested Post'
        END AS PostType
    FROM PostHierarchy PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE P.ClosedDate IS NOT NULL
),
AggregatePostData AS (
    SELECT 
        CP.PostId,
        CP.Title,
        CP.Score,
        CP.ViewCount,
        CP.CreationDate,
        PS.Upvotes,
        PS.Downvotes,
        PS.TotalVotes,
        CP.PostLevel,
        CP.PostType,
        ROW_NUMBER() OVER (PARTITION BY CP.PostLevel ORDER BY CP.CreationDate DESC) AS Rank
    FROM ClosedPosts CP
    JOIN PostVoteSummary PS ON CP.PostId = PS.PostId
)
SELECT 
    AP.PostId,
    AP.Title,
    AP.Score,
    AP.ViewCount,
    AP.CreationDate,
    AP.Upvotes,
    AP.Downvotes,
    AP.TotalVotes,
    AP.PostLevel,
    AP.PostType
FROM AggregatePostData AP
WHERE AP.Rank <= 10
ORDER BY AP.PostLevel, AP.CreationDate DESC;
