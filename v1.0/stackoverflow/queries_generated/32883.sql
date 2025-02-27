WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.Score,
        P.CreationDate,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Only include questions as the root

    UNION ALL

    SELECT 
        P2.Id AS PostId,
        P2.Title,
        P2.OwnerUserId,
        P2.Score,
        P2.CreationDate,
        Level + 1
    FROM 
        Posts P2
    JOIN 
        Posts P1 ON P1.Id = P2.ParentId
    WHERE 
        P1.PostTypeId = 1  -- Ensure the parent is a question
)
SELECT 
    U.DisplayName AS Author,
    RTH.PostId,
    RTH.Title,
    COUNT(C.Id) AS CommentCount,
    SUM(V.BountyAmount) AS TotalBounty,
    COUNT(V2.Id) AS Upvotes,
    ROW_NUMBER() OVER (PARTITION BY RTH.PostId ORDER BY RTH.CreationDate DESC) AS PostRank,
    CASE 
        WHEN SUM(V.BountyAmount) > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS HasBounty
FROM 
    RecursivePostHierarchy RTH
JOIN 
    Users U ON RTH.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON C.PostId = RTH.PostId
LEFT JOIN 
    Votes V ON V.PostId = RTH.PostId AND V.VoteTypeId = 8  -- BountyStart
LEFT JOIN 
    Votes V2 ON V2.PostId = RTH.PostId AND V2.VoteTypeId = 2  -- UpMod
GROUP BY 
    U.DisplayName, RTH.PostId, RTH.Title, RTH.CreationDate
HAVING 
    COUNT(C.Id) > 5  -- Only include posts with more than 5 comments
ORDER BY 
    TotalBounty DESC, PostRank;
