WITH RecursivePostHierarchy AS (
    -- Base case: select all questions
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Question type

    UNION ALL

    -- Recursive case: select answers for each question
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy R ON P.ParentId = R.PostId
    WHERE 
        P.PostTypeId = 2  -- Answer type
),
UserStats AS (
    -- Aggregate user statistics
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBounties,
        SUM(V.VoteTypeId = 2) AS Upvotes,
        SUM(V.VoteTypeId = 3) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostHistoryStats AS (
    -- Aggregate post history changes
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 24 THEN 1 END) AS EditCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)

SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.TotalBounties,
    U.Upvotes,
    U.Downvotes,
    PH.CloseReopenCount,
    PH.EditCount,
    ph.Title AS PostTitle,
    DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS UserRank,
    ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate) AS PostOrder
FROM 
    UserStats U
JOIN 
    RecursivePostHierarchy PH ON U.Id = PH.OwnerUserId
JOIN 
    PostHistoryStats PH ON PH.PostId = PH.PostId
WHERE 
    U.Reputation > 1000 -- Filter users with higher reputation
    AND (U.Upvotes - U.Downvotes) > 50 -- Filter users with positive vote net
ORDER BY 
    U.Reputation DESC;
