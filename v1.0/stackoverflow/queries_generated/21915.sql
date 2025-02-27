WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
AggregatedVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    ag.UpVotes,
    ag.DownVotes,
    ag.TotalVotes,
    ub.BadgeNames,
    rp.CommentCount,
    CASE 
        WHEN rp.Rank = 1 THEN 'Top Post'
        WHEN rp.CommentCount > 10 THEN 'Highly Discussed'
        ELSE 'Regular Post'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    AggregatedVotes ag ON rp.PostId = ag.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.Rank <= 5 OR ag.UpVotes > 10 
ORDER BY 
    rp.ViewCount DESC, 
    rpScore DESC 
LIMIT 100;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: Assigns a rank to posts based on their score and counts comments for each post.
   - `AggregatedVotes`: Aggregates votes for each post, distinguishing between upvotes and downvotes.
   - `UserBadges`: Concatenates badge names for each user, counting the number of badges.

2. **SELECT Statement**: 
   - Retrieves relevant post data and includes aggregated vote counts, badge information, and a derived status for each post based on certain conditions.

3. **JOINs**: 
   - Left joins other CTEs to gather additional data.

4. **WHERE Clause**: 
   - Filters to show either the top 5 ranked posts or those with more than 10 upvotes.

5. **ORDER BY & LIMIT**: 
   - Orders by view count and score in descending order, limiting the final output to a maximum of 100 posts.

This SQL query is complex and showcases various SQL concepts such as CTEs, window functions, aggregated calculations, and conditional logic.
