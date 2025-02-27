WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1
),
ClosedPostsInfo AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        PH.UserId,
        PH.PostHistoryTypeId,
        STRING_AGG(PH.Comment, '; ') FILTER (WHERE PH.PostHistoryTypeId = 10) AS CloseReasons
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId, PH.UserId, PH.PostHistoryTypeId, PH.CreationDate
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UReputation.ReputationRank,
    PP.Title,
    PP.Score,
    PP.ViewCount,
    COALESCE(CP.CloseReasons, 'Not Closed') AS CloseReasons
FROM 
    Users U
LEFT JOIN 
    UserReputation UReputation ON UReputation.UserId = U.Id
INNER JOIN 
    PopularPosts PP ON PP.OwnerUserId = U.Id AND PP.ScoreRank <= 5
LEFT JOIN 
    ClosedPostsInfo CP ON CP.PostId = PP.PostId
WHERE 
    U.Reputation >= 1000
    AND NOT EXISTS (
        SELECT 1 
        FROM Votes V 
        WHERE V.PostId = PP.PostId AND V.VoteTypeId IN (2, 3) -- Exclude posts with upvotes or downvotes
    )
ORDER BY 
    U.Reputation DESC, 
    PP.Score DESC;

### Explanation of the Query:
1. **Common Table Expressions (CTEs)**:
   - `UserReputation`: Retrieves users along with their reputations ranked in descending order.
   - `PopularPosts`: Selects popular posts (questions) ordered by their scores, ranking them for each user.
   - `ClosedPostsInfo`: Aggregates comments related to closed posts, combining multiple close reasons into a single string.

2. **Main Query**:
   - Selects user details along with their popular post titles, scores, view counts, and close reasons (if any).
   - Uses `LEFT JOIN` to bring in user information, popular posts, and closed post information.
   - Applies conditional aggregation (`STRING_AGG`) to concatenate multiple close reasons.
   - Includes filters to only select users with a reputation of 1000 or more and ensures no upvotes or downvotes exist for the selected posts.

3. **Distinct Logic**:
   - The query excludes posts that are either upvoted or downvoted by the voting table, ensuring a focused study on performance and interaction without biases from voting.
  
4. **Ordering**:
   - Results are ordered by reputation and post score for clear insights into users with both high reputation and engagement in popular posts.

This query can serve as a benchmark for performance against different database setups, incorporating advanced SQL techniques while presenting meaningful analytical outputs.
