WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(POST_TYPES.Name, 'Unknown') AS PostType,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankPerUser,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id 
           AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id 
           AND v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes ON p.PostTypeId = PostTypes.Id
),
PostsWithBadges AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.PostType,
        ub.Reputation AS UserReputation,
        B.Name AS BadgeName,
        B.Class AS BadgeClass
    FROM 
        RankedPosts rp
    JOIN 
        Users ub ON rp.OwnerUserId = ub.Id
    LEFT JOIN 
        Badges B ON B.UserId = ub.Id AND B.Date <= rp.CreationDate
    WHERE 
        rp.RankPerUser = 1
)
SELECT 
    pb.PostId,
    pb.Title,
    pb.CreationDate,
    pb.ViewCount,
    pb.Score,
    pb.PostType,
    pb.UserReputation,
    COALESCE(pb.BadgeName, 'No Badge') AS BadgeName,
    COUNT(CASE WHEN comments.IsSpam IS NOT NULL THEN 1 END) AS SpamComments,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM 
    PostsWithBadges pb
LEFT JOIN 
    Comments comments ON comments.PostId = pb.PostId
LEFT JOIN 
    LATERAL (
        SELECT 
            DISTINCT TRIM(UNNEST(STRING_TO_ARRAY(pb.Title, ' '))) AS TagName 
        FROM 
            Tags t
        WHERE 
            LOWER(t.TagName) = LOWER(TRIM(UNNEST(STRING_TO_ARRAY(pb.Title, ' ')))) 
    ) t ON true
WHERE 
    pb.Score >= 0
GROUP BY 
    pb.PostId, pb.Title, pb.CreationDate, pb.ViewCount, pb.Score, pb.PostType, pb.UserReputation, pb.BadgeName
ORDER BY 
    pb.Score DESC, pb.CreationDate DESC
LIMIT 10;

### Explanation of the Query:

1. **CTEs**: 
   - `RankedPosts`: This CTE ranks posts for each user based on the creation date, calculates the number of upvotes and downvotes, and associates the post type.
   - `PostsWithBadges`: This CTE retrieves the most recent post for each user, joins with the Badges table to associate badges that were earned before or on the post's creation date.

2. **Window Functions**: The `RANK()` function is used to assign a rank to each post for each user based on the creation date.

3. **LEFT JOIN**: Used to associate posts with badges, and to link comments to a given post. 

4. **Correlated Subqueries**: Inside CTE for `RankedPosts`, counts for upvotes and downvotes for each post are fetched respectively.

5. **Aggregations**: The final SELECT statement performs aggregation on the tags and counts the number of potentially spam comments.

6. **Predicate Logic**: The query applies several conditions, including filtering out posts with negative scores.

7. **String Expressions**: The `STRING_TO_ARRAY` function is employed to extract potential tags from a post title.

8. **NULL Logic**: Uses `COALESCE` to ensure that if no badge exists, a default value is provided.

9. **Limit and Order**: The result is ordered by score and creation date, and limited to the top 10 results.

This elaborate structure captures multiple SQL constructs and allows for deep performance benchmarking and insights into user engagement on the posts.
