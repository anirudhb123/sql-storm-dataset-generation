WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(NULLIF(SUBSTRING_INDEX(p.Body, '<h1>', -1), ''), 'No body content') AS PostBodyExcerpt
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    u.DisplayName,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    SUM(v.BountyAmount) AS TotalBounties,
    MAX(rc.PostBodyExcerpt) AS MostScoredPostExcerpt,
    COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount,
    MAX(CASE WHEN rp.RankByScore = 1 THEN rp.Title END) AS TopPostTitle
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Votes v ON u.Id = v.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId
WHERE 
    u.Reputation > 1000 
    AND u.CreationDate < NOW() - INTERVAL '6 months'
GROUP BY 
    u.DisplayName
HAVING 
    BadgeCount > 2 
ORDER BY 
    TotalBounties DESC, BadgeCount DESC NULLS LAST
LIMIT 10;

### Explanation:
1. **Common Table Expression (CTE)**: The `RankedPosts` CTE ranks posts by score, counts comments, and extracts an excerpt of the post body, while also ensuring that only posts from the last year are included.
2. **Joins**: Left joins are utilized to gather information about badges, votes, and post histories while maintaining all users.
3. **Aggregate Functions**: Various aggregates such as `COUNT`, `SUM`, and `MAX` summarize the data per user.
4. **Conditional Aggregates**: A conditional sum for counting the 'CloseCount' (number of times a post was closed) demonstrates the use of conditional expressions in aggregates.
5. **COALESCE and NULLIF**: These constructs handle potential NULL values and provide default strings for user-friendly output, such as the post body excerpt.
6. **HAVING Clause**: This filters after aggregation, ensuring only users with more than two badges are represented.
7. **NULL Handling**: `NULLS LAST` ensures that if there are ties in total bounties or badge counts, users without any bounties will appear last.
8. **String Manipulation**: Using `SUBSTRING_INDEX` simulates grasping a portion of the post body for concise reporting.

This query showcases advanced SQL techniques, combines multiple complex operations, and provides insights into user activities on the platform over the last year.
