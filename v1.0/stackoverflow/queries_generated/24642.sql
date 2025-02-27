WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesReceived,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesReceived,
        COUNT(DISTINCT P.Id) AS PostsCount,
        COUNT(DISTINCT C.Id) AS CommentsCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        U.Reputation >= 1000
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotesReceived,
        DownVotesReceived,
        PostsCount,
        CommentsCount,
        ROW_NUMBER() OVER (ORDER BY UpVotesReceived DESC, DownVotesReceived ASC) AS UserRank
    FROM 
        UserActivity
),
WorstClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.CreationDate AS ClosingDate,
        PH.Comment AS CloseReason,
        DENSE_RANK() OVER (ORDER BY PH.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10  -- Closed post
        AND PH.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(TRIM(t.TagName), ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        Tags t ON P.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        P.PostTypeId = 1  -- Only questions
    GROUP BY 
        P.Id
)
SELECT 
    TU.DisplayName,
    TU.UpVotesReceived,
    TU.DownVotesReceived,
    TU.PostsCount,
    TU.CommentsCount,
    WCP.PostId,
    WCP.Title AS ClosedPostTitle,
    WCP.ClosingDate,
    WCP.CloseReason,
    PT.Tags
FROM 
    TopUsers TU
LEFT JOIN 
    WorstClosedPosts WCP ON TU.UserId = WCP.PostId
LEFT JOIN 
    PostTags PT ON WCP.PostId = PT.PostId
WHERE 
    TU.UserRank <= 10
ORDER BY 
    TU.UpVotesReceived DESC, 
    TU.DownVotesReceived ASC;

### Explanation of the Query
1. **Common Table Expressions (CTEs)**: 
    - `UserActivity`: Calculates user engagement metrics such as upvotes received, downvotes received, post counts, and comment counts for users with a reputation above 1000.
    - `TopUsers`: Ranks users based on their upvotes and downvotes.
    - `WorstClosedPosts`: Tracks closed posts in the past year and ranks them.
    - `PostTags`: Gathers tags for posts of type questions.

2. **Aggregations and Logic**:
    - Uses `LEFT JOIN` to ensure that users who may not have received any votes are still represented.
    - Utilizes aggregate functions such as `SUM` and `STRING_AGG`.

3. **Window Functions**:
    - `ROW_NUMBER()` to rank users based on activity.
    - `DENSE_RANK()` to rank closed posts based on closure date.

4. **Complex Filtering and `WHERE` Clause**:
    - Filters for high-reputation users and only prioritizes question posts.

5. **Final Selection and Ordering**:
    - Joins the results from various CTEs and outputs the top users along with details of the worst-performing closed posts associated with them. The final output is ordered by upvotes received and downvotes.

This query combines various SQL features to ensure robust behavior and performance analysis across user activities, closed posts, and post tagging in a Stack Overflow-like schema.
