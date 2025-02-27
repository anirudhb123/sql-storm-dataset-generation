WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.AcceptedAnswerId,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId, p.AcceptedAnswerId
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpvotes,
        SUM(u.DownVotes) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Upvotes,
    rp.Downvotes,
    cp.CloseReason,
    us.DisplayName,
    us.BadgeCount,
    us.TotalUpvotes - us.TotalDownvotes AS NetReputation
FROM 
    RecentPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId AND cp.rn = 1
JOIN 
    UserStats us ON rp.OwnerUserId = us.UserId
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.CreationDate DESC, 
    us.NetReputation ASC NULLS LAST;

### Explanation:
- **Common Table Expressions (CTEs)**:
  - **RecentPosts**: Fetches recent posts along with their total upvotes and downvotes. It uses `COALESCE` to handle cases where a post has no votes. The `ROW_NUMBER` is used to rank the posts per user.
  - **ClosedPosts**: Identifies posts that were closed, along with the reason, and ranks them by their closure date.
  - **UserStats**: Collects statistics for users, summing up their total upvotes and downvotes, and counting their badges.

- **Main Query**: Combines the results from multiple CTEs to create a summary of posts, including their close reason (if applicable), the author's display name, badge count, and a calculated net reputation.

- **NULL Logic**: It handles scenarios where posts may be created without user votes and ensures some results can show despite empty vote data using `COALESCE`.

- **Ordering**: The results are ordered first by creation date and then by net reputation, applying `ASC NULLS LAST` to handle users with no reputation correctly.

This query engages many SQL concepts and constructs while providing a detailed overview of recent posts along with summary statistics from users, taking into consideration various states of the posts (including closures).
