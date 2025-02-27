WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(vote.Upvotes, 0) AS Upvotes,
        COALESCE(vote.Downvotes, 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            PostId,
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes
         FROM 
            Votes 
         GROUP BY PostId) AS vote ON vote.PostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, vote.Upvotes, vote.Downvotes
),
PostStatistics AS (
    SELECT 
        rp.OwnerUserId, 
        COUNT(rp.PostId) AS TotalPosts,
        SUM(rp.Upvotes) AS TotalUpvotes,
        SUM(rp.Downvotes) AS TotalDownvotes,
        MAX(rp.CommentCount) AS MaxComments,
        AVG(rp.CloseCount) AS AvgCloseCount,
        AVG(rp.ReopenCount) AS AvgReopenCount
    FROM 
        RankedPosts rp
    GROUP BY 
        rp.OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ps.TotalPosts,
    ps.TotalUpvotes,
    ps.TotalDownvotes,
    ps.MaxComments,
    ps.AvgCloseCount,
    ps.AvgReopenCount,
    CASE 
        WHEN ps.TotalPosts IS NULL THEN 'No Posts'
        ELSE 'Active Contributor'
    END AS ContributionStatus
FROM 
    Users u
LEFT JOIN 
    PostStatistics ps ON u.Id = ps.OwnerUserId
WHERE 
    u.Reputation > 1000
ORDER BY 
    ps.TotalUpvotes DESC NULLS LAST,
    ps.TotalPosts DESC NULLS LAST;

This SQL query performs the following complex operations:

1. It begins by creating a CTE called `RankedPosts` that gathers posts created in the last year, calculates the number of upvotes and downvotes for each post, and counts comments associated with each post.
2. It then adds logic to count how many times each post has been closed or reopened.
3. A second CTE `PostStatistics` aggregates post statistics by user, including total posts, total upvotes, total downvotes, and average close/reopen counts.
4. Finally, it selects user details and their respective statistics while applying certain predicates and calculated fields to classify users based on their activity and contribution levels.
5. The query applies ordering with special handling for NULL values to adjust the interpretation of the output concerning user contributions.

This complex structure illustrates various SQL constructs such as CTEs, nested aggregation, outer joins, and conditional expressions—all designed for performance benchmarking and deeper insights into user activity.
