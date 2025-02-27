WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL AND V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN V.Id IS NOT NULL AND V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        SUM(CASE WHEN P.ViewCount IS NOT NULL THEN P.ViewCount ELSE 0 END) AS TotalViews,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.OwnerUserId, P.PostTypeId
),
TopUsers AS (
    SELECT 
        U.DisplayName, 
        U.Id, 
        U.Reputation
    FROM 
        UserReputation U
    WHERE 
        U.Reputation > (SELECT AVG(Reputation) FROM Users)
    ORDER BY 
        U.Reputation DESC
    LIMIT 5
)
SELECT 
    U.DisplayName AS TopUser,
    P.Title AS PostTitle,
    COALESCE(PS.CommentCount, 0) AS TotalComments,
    COALESCE(PS.UpvoteCount, 0) AS TotalUpvotes,
    COALESCE(PS.DownvoteCount, 0) AS TotalDownvotes,
    PS.TotalViews AS TotalViews,
    DENSE_RANK() OVER (PARTITION BY U.Id ORDER BY PS.TotalViews DESC) AS ViewRank,
    CASE 
        WHEN PS.PostTypeId = 1 THEN 'Question'
        WHEN PS.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostTypeLabel
FROM 
    TopUsers U
LEFT JOIN 
    PostStatistics PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    Posts P ON PS.PostId = P.Id
WHERE 
    PS.TotalViews IS NOT NULL
ORDER BY 
    U.Reputation DESC, PS.TotalViews DESC;

-- Additional Clause: Choosing only the top ranked posts by users with an unusual post type
WITH FilteredPosts AS (
    SELECT 
        P.*, 
        PT.Name AS PostTypeName
    FROM 
        Posts P
    INNER JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        PT.Name IN ('Answer')  -- Only looking for "Answer" type posts
)
SELECT * 
FROM FilteredPosts
WHERE
    EXISTS (SELECT 1 FROM Votes V WHERE V.PostId = FilteredPosts.Id AND V.VoteTypeId = 2)
ORDER BY 
    FilteredPosts.CreationDate DESC;
