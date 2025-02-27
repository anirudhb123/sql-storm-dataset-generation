WITH PostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(SUM(v.VoteTypeId), 0) DESC) AS PopularityRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY
        p.Id, p.Title, p.PostTypeId, p.CreationDate
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.PostId END) AS UpvotedPostsCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.PostId END) AS DownvotedPostsCount,
        COUNT(DISTINCT ph.PostId) AS ClosedPostCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN
        ClosedPosts ph ON u.Id = ph.PostId 
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    cs.FirstClosedDate,
    ue.UserId,
    ue.DisplayName,
    ue.UpvotedPostsCount,
    ue.DownvotedPostsCount,
    ue.ClosedPostCount,
    CASE 
        WHEN ps.PopularityRank = 1 AND ps.CommentCount > 10 THEN 'Hot'
        WHEN ps.PopularityRank <= 5 THEN 'Trending'
        ELSE 'Regular'
    END AS PostCategory
FROM 
    PostStats ps
LEFT JOIN 
    ClosedPosts cs ON ps.PostId = cs.PostId
LEFT JOIN 
    UserEngagement ue ON ue.ClosedPostCount > 0 OR ue.UpvotedPostsCount > 0
WHERE 
    ps.TotalBounty > 100
ORDER BY 
    ps.CreationDate DESC NULLS LAST, 
    ps.UpvoteCount DESC;

In this query:

- CTE `PostStats` aggregates post information including total bounty, comment count, upvotes, downvotes, and assigns a rank based on vote count.
- CTE `ClosedPosts` identifies posts that has been closed, capturing the first closed date.
- CTE `UserEngagement` captures users who have engaged with posts via upvoting, downvoting, and the number of posts they've closed.
- The final `SELECT` retrieves data from these CTEs and enriches it by categorizing posts based on their rank and comment count. It includes conditional logic to define 'Hot', 'Trending', and 'Regular' categories.
- The `WHERE` clause filters for posts with a total bounty greater than 100.
- The results are ordered by creation date and then by upvote count, managing NULL values with specific sorting criteria.
