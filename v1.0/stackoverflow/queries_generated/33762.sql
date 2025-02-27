WITH RecursivePosts AS (
    -- CTE to traverse posts and their linked related posts
    SELECT 
        P.Id AS PostId,
        P.Title,
        1 AS Level
    FROM 
        Posts P

    UNION ALL

    SELECT 
        PL.RelatedPostId AS PostId,
        RP.Title,
        Level + 1 AS Level
    FROM 
        PostLinks PL
    JOIN 
        RecursivePosts RP ON PL.PostId = RP.PostId
),
AggregatedVotes AS (
    -- Aggregate votes per post and user
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
ClosedPosts AS (
    -- Get posts with a close reason and their details
    SELECT 
        P.Id AS PostId,
        PH.CreationDate,
        PH.Comment AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId = 10
),
TopUsers AS (
    -- Get top users by reputation
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Ranking
    FROM 
        Users U
)
SELECT 
    R.PostId,
    R.Title,
    COALESCE(AV.Upvotes, 0) AS Upvotes,
    COALESCE(AV.Downvotes, 0) AS Downvotes,
    CP.CloseReason,
    CP.CreationDate AS ClosedDate,
    TU.DisplayName AS TopUser,
    TU.Reputation
FROM 
    RecursivePosts R
LEFT JOIN 
    AggregatedVotes AV ON R.PostId = AV.PostId
LEFT JOIN 
    ClosedPosts CP ON R.PostId = CP.PostId
LEFT JOIN 
    TopUsers TU ON TU.Ranking <= 5 -- Top 5 users by reputation
WHERE 
    R.Level <= 3 -- Limit depth of related linked posts
ORDER BY 
    R.PostId, 
    AV.Upvotes DESC, 
    AV.Downvotes ASC;
