WITH PostBadgeCounts AS (
    SELECT p.OwnerUserId,
           COUNT(DISTINCT b.Id) AS BadgeCount,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Posts p
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts from the last year
    GROUP BY p.OwnerUserId
),
TopUsers AS (
    SELECT u.Id,
           u.DisplayName,
           u.Reputation,
           COALESCE(pbc.BadgeCount, 0) AS TotalBadges,
           DENSE_RANK() OVER (ORDER BY COALESCE(pbc.BadgeCount, 0) DESC, u.Reputation DESC) as UserRank
    FROM Users u
    LEFT JOIN PostBadgeCounts pbc ON u.Id = pbc.OwnerUserId
    WHERE u.Reputation > 1000 -- Only users with more than 1000 reputation
),

PostStatistics AS (
    SELECT p.OwnerUserId,
           COUNT(p.Id) AS PostCount,
           AVG(COALESCE(p.ViewCount, 0)) AS AvgViews,
           MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),

FinalStats AS (
    SELECT tu.Id AS UserId,
           tu.DisplayName,
           tu.TotalBadges,
           ps.PostCount,
           ps.AvgViews,
           DATEDIFF(day, ps.LastPostDate, GETDATE()) AS DaysSinceLastPost,
           CASE 
               WHEN tu.TotalBadges > 10 THEN 'Veteran'
               WHEN tu.TotalBadges > 5 THEN 'Enthusiast'
               ELSE 'Novice'
           END AS UserCategory
    FROM TopUsers tu
    LEFT JOIN PostStatistics ps ON tu.Id = ps.OwnerUserId
)

SELECT UserId,
       DisplayName,
       TotalBadges,
       PostCount,
       AvgViews,
       DaysSinceLastPost,
       UserCategory,
       CASE 
           WHEN DaysSinceLastPost > 365 THEN 'Inactive'
           ELSE 'Active'
       END AS Activity
FROM FinalStats
WHERE UserRank <= 100 -- Top 100 users based on badge counts and reputation
ORDER BY TotalBadges DESC, Reputation DESC;

### Explanation:
This SQL query provides a performance benchmarking profile of the top 100 users on a Stack Overflow-like platform based on their badge counts and reputation. It employs several advanced SQL constructs:

1. **Common Table Expressions (CTEs)**:
   - `PostBadgeCounts` calculates the number of badges held by users along with their types.
   - `TopUsers` ranks users based on their badge count and reputation.
   - `PostStatistics` aggregates posts per user, including average view counts and the date of their last post.
   - `FinalStats` combines data from the previous CTEs to generate a detailed user profile.

2. **Window Functions**:
   - `DENSE_RANK()` is used to rank users with the same badge count while prioritizing their reputation.

3. **Handling NULLs**:
   - `COALESCE()` is employed to handle cases where users may not have associated badges or posts.

4. **CASE Statements**:
   - Several CASE statements categorize users based on their badge counts and provide insight into their activity level.

5. **Complex Aggregations**:
   - The query aggregates data across multiple relationships, demonstrating advanced SQL logic within a single query.

The resulting dataset from this query is useful for provides insights into user engagement and contribution levels in the community, facilitating performance benchmarking and potential rewards mapping.
