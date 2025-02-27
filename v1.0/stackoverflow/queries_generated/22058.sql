WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT b.Class) AS DistinctBadgeClasses
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostsWithHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS LastEditDate,
        STRING_AGG(ph.Comment, '; ') FILTER (WHERE ph.Comment IS NOT NULL) AS EditComments
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Titles, Bodies, Tags edits
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.PostRank,
    upv.UpVotes,
    upv.DownVotes,
    ub.BadgeCount,
    ub.DistinctBadgeClasses,
    COALESCE(ph.LastEditDate, 'Never Edited') AS LastEdit,
    COALESCE(ph.EditComments, 'No comments') AS EditComments
FROM 
    RankedPosts rp
LEFT JOIN 
    (SELECT PostId, UpVotes, DownVotes FROM (SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes FROM Votes GROUP BY PostId) AS votes) upv ON rp.PostId = upv.PostId
LEFT JOIN 
    UsersWithBadges ub ON rp.PostId IN (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    PostsWithHistory ph ON rp.PostId = ph.PostId
WHERE 
    (rp.PostRank = 1 OR rp.PostRank IS NULL) -- Only top ranked posts or bypassing null logic
ORDER BY 
    rp.Score DESC,
    rp.ViewCount DESC
LIMIT 50;

### Explanation:

1. **RankedPosts CTE**: This Common Table Expression (CTE) ranks posts for each type based on their scores and calculates the vote counts (upvotes and downvotes) while filtering for posts created in the last year.

2. **UsersWithBadges CTE**: This aggregates data about users, counting the total badges they have and the number of distinct badge classes.

3. **PostsWithHistory CTE**: Captures the history of edits associated with posts, concatenating all edit comments into a single string for easy viewing.

4. **Main Query**: Combines these three CTEs to provide a comprehensive view of each post that:
   - Displays the title, creation date, view count, ranking, associated vote counts, user badge info, and last edit details.
   - Incorporates complex filtering with NULL logic and subquery structures to ensure that only relevant, detailed information is presented.

5. **Set Operations and Conditions**: Uses `STRING_AGG` for comments, flexible date filtering across multiple tables, and checks to manage NULL values explicitly.

6. **Sorting and Limit**: Sorts by score and view count, limiting the output to the top 50 posts, allowing for performance benchmarking focused on popular posts.
