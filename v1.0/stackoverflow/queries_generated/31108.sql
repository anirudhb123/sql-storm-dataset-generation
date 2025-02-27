WITH RecursivePostHierarchy AS (
    -- CTE to recursively find the hierarchy of posts (Questions and Answers)
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        P.Title,
        P.CreationDate,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Questions

    UNION ALL

    SELECT 
        P.Id,
        P.ParentId,
        P.Title,
        P.CreationDate,
        Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy RPH ON P.ParentId = RPH.PostId
    WHERE 
        P.PostTypeId = 2  -- Answers
),

UserReputation AS (
    -- CTE to calculate the total reputation of users who have answered questions with high view counts
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(U.Reputation) AS TotalReputation
    FROM 
        Users U
    INNER JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 2 AND  -- Answers
        P.ViewCount > 1000 -- Only consider answers for questions with more than 1000 views
    GROUP BY 
        U.Id
),

ClosedPostCounts AS (
    -- CTE to count the number of times posts have been closed or reopened 
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseOpenCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)

SELECT 
    RPH.PostId,
    RPH.Title,
    RPH.CreationDate,
    RPH.Level,
    COALESCE(U.TotalReputation, 0) AS UserReputation,
    COALESCE(CPC.CloseOpenCount, 0) AS PostCloseOpenCount
FROM 
    RecursivePostHierarchy RPH
LEFT JOIN 
    UserReputation U ON RPH.PostId = U.UserId 
LEFT JOIN 
    ClosedPostCounts CPC ON RPH.PostId = CPC.PostId
WHERE 
    RPH.Level = 1  -- Targeting only questions (level 1)
ORDER BY 
    UsersRepQuery DESC,
    PostCloseOpenCount DESC,
    RPH.CreationDate DESC
LIMIT 100;  -- Limiting the results for performance benchmarking
