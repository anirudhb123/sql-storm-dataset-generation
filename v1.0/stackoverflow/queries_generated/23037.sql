WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS TotalUpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        RANK() OVER (ORDER BY COALESCE(SUM(V.VoteTypeId = 2) - SUM(V.VoteTypeId = 3), 0) DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
PostClosedCount AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS ClosedPosts
    FROM 
        Posts P
    WHERE 
        P.Id IN (SELECT DISTINCT PostId FROM PostHistory WHERE PostHistoryTypeId = 10)
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.TotalUpVotes,
        U.TotalDownVotes,
        COALESCE(C.ClosedPosts, 0) AS ClosedPosts,
        U.ReputationRank
    FROM 
        UserStats U
    LEFT JOIN 
        PostClosedCount C ON U.UserId = C.OwnerUserId
    WHERE 
        U.TotalPosts > 10
    ORDER BY 
        U.ReputationRank
    LIMIT 5
)
SELECT 
    T.DisplayName,
    T.TotalUpVotes,
    T.TotalDownVotes,
    T.ClosedPosts,
    CASE 
        WHEN T.ClosedPosts > 5 THEN 'High Closure'
        WHEN T.ClosedPosts BETWEEN 1 AND 5 THEN 'Moderate Closure'
        ELSE 'No Closure'
    END AS ClosureCategory,
    JSON_AGG(
        DISTINCT JSON_BUILD_OBJECT(
            'PostId', P.Id,
            'Title', P.Title,
            'CreationDate', P.CreationDate,
            'ViewCount', P.ViewCount,
            'Score', P.Score
        )
    ) AS ClosedPostsDetails
FROM 
    TopUsers T
LEFT JOIN 
    Posts P ON T.UserId = P.OwnerUserId 
WHERE 
    P.Id IN (SELECT DISTINCT PostId FROM PostHistory WHERE PostHistoryTypeId = 10)
GROUP BY 
    T.UserId, T.DisplayName, T.TotalUpVotes, T.TotalDownVotes, T.ClosedPosts
ORDER BY 
    T.ReputationRank;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - **UserStats**: This CTE aggregates data for users including upvotes, downvotes, the total number of posts and comments, and ranks them based on the difference between upvotes and downvotes.
   - **PostClosedCount**: Counts the number of closed posts for each user.
   - **TopUsers**: Combines data from `UserStats` and `PostClosedCount`, filtering for users with more than 10 posts and limiting the result to the top 5 ranked users.

2. **Main Query**: 
   - It extracts detailed information about closed posts performed by the top users and categorizes the number of closed posts into 'High Closure', 'Moderate Closure', and 'No Closure'.
   - It uses `JSON_AGG` to collate details of closed posts into a JSON array.

3. **Complex Constructs**:
   - Utilizes **LEFT JOINs** for gathering user and post data without excluding users with no posts or closed posts.
   - Implements **COALESCE** to handle NULL values gracefully.
   - Employs **window functions** for ranking users.
   - Uses **nested SELECTs** and JSON functions for intricate data aggregation and formatting.

4. **Semantic Cases**:
   - Incorporates conditional logic to categorize closed posts while also dynamically creating JSON objects for better readability and utility.
