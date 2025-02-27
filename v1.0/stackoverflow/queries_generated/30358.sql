WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        P.CreationDate,
        1 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL  -- Starting point, root posts (Questions)

    UNION ALL

    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ParentId,
        P.CreationDate,
        R.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy R ON P.ParentId = R.PostId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000 -- Filtering to users with high reputation
),
RecentPosts AS (
    SELECT 
        P.*, 
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)  -- Considering only BountyStart and BountyClose votes
    GROUP BY 
        P.Id
),
FilteredUserPostStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000  -- Only considering high-reputation users
    GROUP BY 
        U.Id
)
SELECT 
    U.DisplayName,
    F.PostCount,
    F.TotalViews,
    F.TotalScore,
    F.LastPostDate,
    R.PostId AS RelatedPostId,
    R.Title AS RelatedPostTitle,
    R.Level AS PostLevel,
    RP.CommentCount AS CommentsOnPost,
    RP.TotalBounty
FROM 
    TopUsers U
JOIN 
    FilteredUserPostStats F ON U.Id = F.UserId
LEFT JOIN 
    RecursivePostHierarchy R ON F.PostCount >= 5 -- Limiting to users with at least 5 posts
LEFT JOIN 
    RecentPosts RP ON R.PostId = RP.Id
WHERE 
    U.ReputationRank <= 100  -- Only top 100 by reputation
ORDER BY 
    U.Reputation DESC, 
    F.LastPostDate DESC;
