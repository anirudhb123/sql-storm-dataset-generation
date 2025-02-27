WITH UserVoteStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN V.VoteTypeId IN (6, 7) THEN 1 ELSE 0 END) AS CloseReopenCount,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(P.ViewCount) DESC) AS ViewRank
    FROM
        Users U
    LEFT JOIN Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON C.UserId = U.Id
    LEFT JOIN Badges B ON B.UserId = U.Id
    LEFT JOIN Votes V ON V.UserId = U.Id
    GROUP BY
        U.Id
),
ActivePostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS TotalUpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS TotalDownVotes,
        COUNT(DISTINCT C.Id) AS CommentCount,
        CASE 
            WHEN P.PostTypeId = 1 THEN 'Question'
            WHEN P.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM
        Posts P
    LEFT JOIN Votes V ON V.PostId = P.Id
    LEFT JOIN Comments C ON C.PostId = P.Id
    WHERE
        P.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY
        P.Id
)
SELECT
    U.DisplayName,
    U.TotalPosts,
    U.TotalComments,
    U.TotalBadges,
    U.TotalViews,
    U.UpVoteCount,
    U.DownVoteCount,
    U.CloseReopenCount,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.TotalUpVotes,
    P.TotalDownVotes,
    P.CommentCount,
    P.PostType
FROM
    UserVoteStats U
LEFT JOIN ActivePostStats P ON P.PostRank = 1 AND P.OwnerUserId = U.UserId
WHERE
    U.UpVoteCount > U.DownVoteCount
    AND U.ViewRank <= 10
ORDER BY
    U.TotalViews DESC, U.DisplayName;

This query performs the following functions:
1. **Common Table Expressions (CTEs)**: The query uses two CTEs to calculate statistics related to users' voting behavior and posts activity over the past year.
   - The first CTE `UserVoteStats` gathers user-related statistics, including upvotes, downvotes, and the number of posts and comments.
   - The second CTE `ActivePostStats` collects information about active posts, including their voting counts and types.

2. **Ranking and Filtering**: The use of `ROW_NUMBER()` to rank both users and posts allows the main query to filter out top-performing users and their most recent posts.

3. **Complex Joins and Aggregation**: The `LEFT JOIN`s ensure that all users are included, even if they have no associated posts or votes. The aggregations aggregate votes and comments for each user and post.

4. **Conditional Logic and COALESCE**: Uses `CASE` to determine the type of post and `COALESCE` to handle cases where there might be no corresponding data for votes or views.

5. **Filtering for Exploration**: The main query filters for users who have more upvotes than downvotes and limits the output to a specific number of top-ranked users based on their views.

6. **Order Results**: The final output is sorted by the total views in descending order and then by the user display name.

This query effectively benchmarks performance across various facets of user engagement on posts while integrating functionality from different parts of the schema in a meaningful and complex manner.
