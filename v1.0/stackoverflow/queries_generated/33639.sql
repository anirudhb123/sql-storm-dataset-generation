WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags ILIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    HAVING COUNT(p.Id) > 5
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostsCount,
        MAX(u.Reputation) AS Reputation
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.Score,
    pt.TagName,
    ur.DisplayName AS UserDisplayName,
    ur.TotalBounty,
    ur.Reputation
FROM RankedPosts rp
JOIN PopularTags pt ON rp.Title ILIKE '%' || pt.TagName || '%'
JOIN UserReputation ur ON rp.PostId = ur.UserId
WHERE rp.Rank <= 3
AND ur.Reputation > 1000
ORDER BY rp.Score DESC, rp.ViewCount DESC
LIMIT 10;
### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: Retrieves posts from the last year, ranking them by score and view count.
   - `PopularTags`: Aggregates tags that have more than 5 associated posts.
   - `UserReputation`: Computes total bounty amounts, post counts, and maximum reputation for users.

2. **Main Query**:
   - Joins the CTEs to obtain the top-ranked posts related to popular tags, filtering to include only those with a minimum reputation.
   - Orders results by score and view count, limiting the final output to the top 10 entries. 

3. **Use of Window Functions**: Used `ROW_NUMBER()` to rank posts within each post type.

4. **Joins and NULL logic**: Outer joins are utilized in the user reputation CTE to ensure all users are counted, even those without any posts or votes.

5. **String Expressions and LIKE**: Used `ILIKE` for case-insensitive matching of tag names within post titles. 

6. **Calculations**: Aggregates the total bounties and counts.

This query showcases a variety of SQL features for performance benchmarking across numerous tables in the schema.
