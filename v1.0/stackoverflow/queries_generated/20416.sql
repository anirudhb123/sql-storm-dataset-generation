WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        COALESCE(b.Name, 'No Badge') AS UserBadge
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON rp.PostId = b.UserId AND b.Class = 1  -- Gold Badge
    WHERE 
        rp.PostRank > 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN up.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN up.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes up ON p.Id = up.PostId
    GROUP BY 
        u.Id
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.CommentCount,
    us.DisplayName AS PostOwner,
    us.TotalUpvotes,
    us.TotalDownvotes,
    us.TotalPosts,
    us.AvgScore,
    CASE 
        WHEN fp.UserBadge = 'No Badge' AND us.TotalPosts = 0 THEN 'New User'
        ELSE 'Active User'
    END AS UserCategory
FROM 
    FilteredPosts fp
JOIN 
    UserStats us ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)
WHERE 
    fp.CommentCount >= 2
    AND (us.TotalUpvotes - us.TotalDownvotes) > 5
ORDER BY 
    fp.CreationDate DESC
LIMIT 100;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: Fetches posts created within the last year, ranks them by the user and creation date, and counts the comments for each post.
   - `FilteredPosts`: Filters out posts where the user's most recent post is not their first and retrieves badge information.
   - `UserStats`: Aggregates user statistics including upvotes, downvotes, total posts, and average score.

2. **Correlated Subqueries**: The `UserId` in the final query is fetched using a correlated subquery which retrieves the owner of the relevant post.

3. **Complex Filtering and Case Logic**: The final selection applies filtering on comment counts and a calculated `UserCategory` based on badge presence and the number of posts, illustrating the SQL logic sophistication.

4. **Window Functions**: Utilizes `ROW_NUMBER()` and `COUNT()` to derive rankings and comment aggregation.

5. **String Expressions**: Includes COALESCE to ensure a default string is used for users without a badge.

This query tests various SQL concepts while fetching insightful metrics from the StackOverflow data structure, lending itself well to performance benchmarking scenarios.
