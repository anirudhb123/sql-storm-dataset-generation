WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes,
        SUM(COALESCE((SELECT COUNT(*) 
                     FROM Comments c 
                     WHERE c.UserId = u.Id), 0)) AS TotalComments
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount 
        FROM Votes 
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    GROUP BY u.Id
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '7 days'
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagPopularity
    FROM Tags t
    JOIN Posts p ON t.Id = ANY (string_to_array(p.Tags, '::int'))
    JOIN PostLinks pl ON p.Id = pl.PostId
    GROUP BY t.TagName
    HAVING COUNT(pt.PostId) > 10
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ua.PostCount,
    ua.TotalVotes,
    ua.TotalComments,
    ARRAY_AGG(p.Title) AS RecentPostTitles,
    COALESCE(rt.TagName, 'No Tags Available') AS PopularTag,
    COALESCE(rt.TagPopularity, 0) AS TagPopularityScore
FROM Users u
LEFT JOIN UserActivity ua ON u.Id = ua.UserId
LEFT JOIN RecentPosts p ON u.Id = p.OwnerUserId AND p.rn <= 5
LEFT JOIN PopularTags rt ON rt.TagPopularity > 50
WHERE u.Reputation > 100 -- filter for users with reputation > 100
GROUP BY u.Id, u.DisplayName, ua.PostCount, ua.TotalVotes, ua.TotalComments
ORDER BY ua.TotalVotes DESC NULLS LAST, u.DisplayName
LIMIT 100;

### Explanation of the Query:
1. **UserActivity CTE**: 
   - Aggregates user activity, counting the number of posts and votes associated with each user, including comments on posts written by the user.

2. **RecentPosts CTE**: 
   - Retrieves recent posts (from the last 7 days) for each user, limiting to 5 recent entries per user using `ROW_NUMBER()`.

3. **PopularTags CTE**: 
   - Identifies tags that have been popular among posts, specifically those associated with more than 10 posts.

4. **Final Selection**:
   - Combines user activity with their recent post titles and popular tags they are associated with, while ensuring a limitation based on user reputation.
   - Provides aggregate data such as total votes and recent post titles, returning a structured view of active users in the last week.

5. **Ordering and Limiting**: 
   - Orders by total votes descending and allows for nulls to be ordered last, ensuring more active users are prioritized in the results.

This query is complex enough to include various SQL constructs, including CTEs, aggregate functions, WINDOW functions, and conditional logic, making it suitable for performance benchmarking with the given schema.
