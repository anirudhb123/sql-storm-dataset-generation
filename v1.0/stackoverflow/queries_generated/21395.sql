WITH ranked_posts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score IS NOT NULL -- Ensure the score is not NULL
),
user_stats AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COALESCE(badge_count, 0) AS BadgeCount,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN p.Score < 0 THEN -p.Score ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
filtered_posts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        us.UserId,
        us.Reputation,
        us.BadgeCount
    FROM 
        ranked_posts rp
    INNER JOIN 
        user_stats us ON us.UserId = rp.OwnerUserId
    WHERE 
        rp.RankScore <= 3 AND us.Reputation >= 100 -- Keep top 3 posts for users with at least 100 reputation
),
post_links_summary AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount,
        STRING_AGG(pl.RelatedPostId::text, ', ') AS RelatedPostIds
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.Score,
    fp.Reputation,
    fp.BadgeCount,
    COALESCE(pl.RelatedPostCount, 0) AS RelatedCount,
    COALESCE(pl.RelatedPostIds, 'None') AS RelatedPostIds
FROM 
    filtered_posts fp
LEFT JOIN 
    post_links_summary pl ON fp.PostId = pl.PostId
WHERE 
    (fp.ViewCount BETWEEN 100 AND 10000 OR fp.Score > 5) -- Views in a certain range or Score above 5
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC
LIMIT 50;

### Explanation of Query Constructs
1. **Common Table Expressions (CTEs)**: Used for structuring the query by breaking it into logical parts (`ranked_posts`, `user_stats`, `filtered_posts`, `post_links_summary`).
2. **Window Functions**: Used in `ranked_posts` to rank posts based on their scores and calculate the number of comments per post.
3. **Outer Joins**: Utilized in various parts of the CTEs to ensure we capture all data even if certain relationships don't exist, such as users without badges or posts without comments.
4. **Aggregations and String Functions**: Used in `user_stats` and `post_links_summary` to count and concatenate related post IDs.
5. **Complicated Predicates**: The final condition filters based on both view counts and scores, allowing for nuanced data selection.
6. **NULL Logic**: Handled via `COALESCE` to ensure no NULLs affect the output - defaults to 0 or 'None' were appropriate.

This query represents a more intricate SQL scenario that combines various functionalities and considerations commonly found in a more extensive SQL environment.
