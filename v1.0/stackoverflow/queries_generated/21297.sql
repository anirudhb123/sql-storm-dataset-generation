WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        pp.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY pp.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
             PostId,
             SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 WHEN vt.Name = 'DownMod' THEN -1 ELSE 0 END) AS Score
         FROM 
             Votes v
         JOIN 
             VoteTypes vt ON v.VoteTypeId = vt.Id
         GROUP BY 
             PostId) pp ON p.Id = pp.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT rp.PostId) AS PostCount,
    SUM(COALESCE(rp.Score, 0)) AS TotalScore,
    MAX(rp.PostRank) AS MaxPostRank,
    STRING_AGG(DISTINCT CASE WHEN rp.PostRank <= 3 THEN rp.Title END, '; ') AS TopPosts,
    ARRAY_AGG(DISTINCT (CASE 
                            WHEN b.Class = 1 THEN 'Gold: ' || b.Name
                            WHEN b.Class = 2 THEN 'Silver: ' || b.Name
                            ELSE 'Bronze: ' || b.Name 
                         END) ORDER BY b.Class) AS Badges
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON rp.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON b.UserId = u.Id
WHERE 
    u.Reputation > 500
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT rp.PostId) > 2 AND MaxPostRank = 1
ORDER BY 
    TotalScore DESC
OFFSET 0 ROWS
FETCH NEXT 10 ROWS ONLY;

### Explanation:

1. **Common Table Expression (CTE)**: The `RankedPosts` CTE computes scores for posts based on upvotes and downvotes. It assigns a rank to each post per user, ordering by score. This helps in spotlighting users with high-scoring posts.

2. **Aggregates and Nested Queries**: Utilizing `COUNT`, `SUM`, and `STRING_AGG` shows users’ contributions and highlights their best posts, creating a summary of their activity over the past year.

3. **Conditional Logic**: The CASE statement categorizes badges into Gold, Silver, and Bronze with contextual labels.

4. **NULL Handling**: The use of `COALESCE` ensures that if there are no votes for a post, it contributes zero to the score.

5. **Join Mechanics**: Outer joins are applied to relate users to their posts and their badges, handling cases where users have zero posts or badges gracefully.

6. **Filters on Grouping**: The `HAVING` clause restricts results to users with a minimum level of activity and elite posts, eliminating less active users.

7. **Pagination**: The query fetches a specific number of result rows, supporting scenarios with potentially large datasets.

8. **String Manipulation**: In the aggregation of titles, it concatenates titles of the top posts efficiently into a single string with delimiters.

9. **Potentially Bizarre Semantics**: Intricate use of window functions and string aggregation in conjunction with conditional logic can lead to less common SQL practices that still deliver meaningful insights.

This SQL query demonstrates a thorough understanding of complex SQL semantics while showcasing user activity in the Stack Overflow schema effectively.
