WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
),
UserVoteSummary AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN c.CreationDate > NOW() - INTERVAL '30 days' THEN 1 ELSE 0 END), 0) AS RecentComments
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(uvs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(uvs.DownVotes, 0) AS TotalDownVotes,
    COALESCE(pr.CommentCount, 0) AS TotalComments,
    COALESCE(pr.RecentComments, 0) AS RecentCommentsCount,
    COALESCE(rp.PostId, -1) AS LatestPostId,
    COALESCE(rp.Title, 'No Posts') AS LatestPostTitle,
    COALESCE(rp.CreationDate, 'No Date') AS LatestPostDate,
    COALESCE(rp.Score, 0) AS LatestPostScore,
    COALESCE(rp.ViewCount, 0) AS LatestPostViewCount
FROM 
    Users u
    LEFT JOIN UserVoteSummary uvs ON u.Id = uvs.UserId
    LEFT JOIN PostsWithComments pr ON u.Id = pr.PostId
    LEFT JOIN RankedPosts rp ON u.Id = rp.PostId AND rp.RowNum = 1
WHERE 
    COALESCE(uvs.UpVotes, 0) - COALESCE(uvs.DownVotes, 0) >= 0
ORDER BY 
    COALESCE(rp.Score, 0) DESC, 
    u.Reputation DESC
LIMIT 100;


### Explanation of the Query:
1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: Identifies the most recent post for each user created in the last year, using `ROW_NUMBER()` to rank the posts.
   - `UserVoteSummary`: Aggregates up and down votes for each user.
   - `PostsWithComments`: Counts the total comments and recent comments on each post.

2. **Main Select Statement**: 
   - Joins Users with their vote summaries, comments summary, and their latest post. 
   - Uses `COALESCE` to handle NULLs, providing defaults where applicable.

3. **WHERE Clause**: 
   - Filters to only include users with a net non-negative vote count (`UpVotes - DownVotes >= 0`).

4. **Ordering and Limiting**: 
   - The results are ordered by the highest post score followed by user reputation, and the limit is set to return the top 100 users.

### Bizarre Semantic Corner Cases:
- The use of `COALESCE` showcases NULL logic handling, allowing defaults for missing data points.
- The ranking of posts per user over a specific interval raises awareness about data accuracy within temporal contexts.
- The combination of aggregate functions with conditional logic provides insights into comment activity over a time frame, highlighting community engagement.

This query should be quite illuminating when it comes to performance benchmarking, considering various database operations like joins, CTEs, window functions, and aggregate calculations.
