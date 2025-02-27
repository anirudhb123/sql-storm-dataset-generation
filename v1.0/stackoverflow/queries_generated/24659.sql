WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        p.Title,
        p.Score,
        u.DisplayName AS Owner,
        RANK() OVER (ORDER BY p.Score DESC) AS OwnerRank
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.Rank <= 5
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    tp.Title AS TopPostTitle,
    tp.Score AS TopPostScore,
    tp.Owner AS PostOwner,
    ub.BadgeCount AS OwnerBadgeCount,
    ub.BadgeNames AS OwnerBadges,
    COALESCE(COUNT(c.Id), 0) AS CommentCount,
    COALESCE(APAVG(c.Score), 0) AS AvgCommentScore,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypeNames
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
LEFT JOIN 
    Users u ON tp.Owner = u.DisplayName
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = tp.PostId) 
GROUP BY 
    tp.Title, tp.Score, tp.Owner, ub.BadgeCount, ub.BadgeNames
HAVING 
    COUNT(c.Id) > 0 OR AVG(c.Score) IS NOT NULL
ORDER BY 
    tp.Score DESC
LIMIT 10;

### Explanation
1. **CTEs**: The query uses multiple CTEs for organization:
   - `RankedPosts`: Ranks posts based on their scores for the last year.
   - `TopPosts`: Selects the top-ranked posts (up to 5 per post type) along with their owners.
   - `UserBadges`: Counts badges for each user and aggregates their names.

2. **Main SELECT**: Combines the results from the CTEs and joins them with `Comments` to count comments, while also computing the average comment score.

3. **Aggregation and Filtering**: Uses `HAVING` to filter results to only include posts with comments or those with a known average comment score.

4. **String Functions**: uses `STRING_AGG` to create a comma-separated list of badge names and distinct post types.

5. **NULL Handling**: Uses `COALESCE` to ensure that default values are returned for counting and averaging where necessary.

This query performs benchmarking by demonstrating complex joins, aggregates, CTEs, and performance elements while adhering to various SQL semantics and corner cases.
