WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS rn
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    us.DisplayName AS Owner,
    us.TotalBounties,
    us.BadgeCount,
    us.CommentCount,
    (SELECT COUNT(*)
     FROM Comments c
     WHERE c.PostId = rp.PostId) AS TotalComments,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Tags t
     WHERE t.Id IN (
         SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(rp.Tags FROM 2 FOR LENGTH(rp.Tags) - 2), '><'))::int[])
     )) AS RelatedTags,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score'
        WHEN rp.Score < 0 THEN 'Negative Score'
        WHEN rp.Score >= 0 AND rp.Score < 5 THEN 'Low Score'
        ELSE 'High Score'
    END AS ScoreCategory
FROM 
    RankedPosts rp
JOIN 
    Users us ON rp.PostId = us.Id
WHERE 
    rp.rn <= 5  -- Only get top 5 posts per type
    AND EXISTS (
         SELECT 1 FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2
         HAVING COUNT(*) > 10
    )
ORDER BY 
    rp.Score DESC,
    rp.CreationDate ASC
FETCH FIRST 10 ROWS ONLY;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: Retrieves posts from the last year, ranking them by score and creation date. It utilizes `ROW_NUMBER()` to limit results per post type.
   - `UserStats`: Aggregates user data, including total bounties, badge counts, and comment counts using LEFT JOINs and aggregations.

2. **Main Query**:
   - Joins `RankedPosts` and `UserStats` to gather necessary information about the posts and respective users.
   - Uses subqueries to calculate total comments per post and to aggregate tag names into a single string with `STRING_AGG`.
   - A `CASE` statement categorizes scores into different levels based on their values.

3. **Predicate Logic**:
   - Implemented the `EXISTS` clause to ensure only posts with more than 10 upvotes are included.

4. **Edge Cases**:
   - Checks for `NULL` scores and categorizes them specifically.
   - The query limits results to the top 5 ranked posts per post type and fetches only the first 10 overall.

This complex query effectively benchmarks performance across various constructs, leveraging multiple SQL features and corner cases.
