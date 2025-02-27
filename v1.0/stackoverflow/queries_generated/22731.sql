WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.ViewCount IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 2000
    GROUP BY 
        u.Id
),
PostComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserPostActivity AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostsCreated
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    ub.BadgeCount,
    COUNT(DISTINCT tp.PostId) AS TopPostCount,
    COALESCE(SUM(pa.Upvotes), 0) AS TotalUpvotes,
    COALESCE(SUM(pa.Downvotes), 0) AS TotalDownvotes,
    COALESCE(SUM(pa.PostsCreated), 0) AS PostsMade
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    TopPosts tp ON u.Id = tp.OwnerUserId
LEFT JOIN 
    UserPostActivity pa ON u.Id = pa.UserId
WHERE 
    ub.BadgeCount IS NOT NULL OR tp.PostId IS NOT NULL
GROUP BY 
    u.Id, ub.BadgeCount
HAVING 
    COUNT(DISTINCT tp.PostId) > 5
ORDER BY 
    TotalUpvotes DESC NULLS LAST,
    u.DisplayName ASC;

### Explanation of Query Components:
1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: Ranks posts within each type based on the score.
   - `TopPosts`: Filters to retain only the top 10 posts per type.
   - `UserBadges`: Counts the number of badges held by users with a reputation greater than 2000.
   - `PostComments`: Counts comments on posts created in the last year.
   - `UserPostActivity`: Summarizes user activities such as upvotes, downvotes, and post creation count.

2. **JOINs**:
   - Multiple LEFT JOINs to aggregate data from the various tables, allowing for NULL values in optional relationships (like badges and comments).

3. **Complex Aggregation**:
   - Main selection aggregates the data across multiple dimensions (users, their badges, their top posts, and vote counts).

4. **Filtering & Ordering**:
   - The result is filtered to include only users with a significant number of top posts and ordered by total upvotes while handling NULL values appropriately.

This query serves as a sophisticated example for performance benchmarking due to its complexity and multi-layer data aggregation, combining ranking, conditional calculations, and multiple relationships.
