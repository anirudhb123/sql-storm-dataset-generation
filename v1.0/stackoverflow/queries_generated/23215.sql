WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS RankByComments
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY p.Id, p.OwnerUserId
),
TopPostUsers AS (
    SELECT 
        pm.OwnerUserId,
        COUNT(pm.PostId) AS PostCount,
        SUM(pm.CommentCount) AS TotalComments,
        AVG(pm.UpVoteCount - pm.DownVoteCount) AS AverageVoteBalance,
        ROW_NUMBER() OVER (ORDER BY COUNT(pm.PostId) DESC) AS UserRank,
        ub.BadgeCount,
        ub.HighestBadgeClass
    FROM PostMetrics pm
    JOIN UserBadges ub ON pm.OwnerUserId = ub.UserId
    GROUP BY pm.OwnerUserId, ub.BadgeCount, ub.HighestBadgeClass
)
SELECT 
    u.DisplayName,
    tpu.PostCount,
    tpu.TotalComments,
    tpu.AverageVoteBalance,
    tpu.BadgeCount,
    CASE 
        WHEN tpu.HighestBadgeClass = 1 THEN 'Gold'
        WHEN tpu.HighestBadgeClass = 2 THEN 'Silver'
        ELSE 'Bronze or No Badge'
    END AS HighestBadge
FROM TopPostUsers tpu
JOIN Users u ON tpu.OwnerUserId = u.Id
WHERE tpu.UserRank <= 10
AND tpu.TotalComments > 5
ORDER BY tpu.PostCount DESC
OPTION (RECOMPILE);

### Explanation:
1. **CTEs**: Several Common Table Expressions (CTEs) are used to break down the query into manageable parts:
   - `UserBadges` aggregates badge information for each user.
   - `PostMetrics` gathers metrics for each post including comment counts and vote counts.
   - `TopPostUsers` combines the previous CTEs to create a summary of user performance based on post engagement.

2. **Window Functions**: `RANK()` and `ROW_NUMBER()` are used to rank users based on their post activity and engagement metrics.

3. **Aggregations and Joins**: Various outer joins and aggregate functions (`COUNT`, `SUM`, `AVG`) help to compile the necessary data from different tables.

4. **Complex Filtering**: The main query filters users with a rank of 10 or less and requires a minimum of 5 comments to be eligible for the final output.

5. **CASE Statement**: This provides a readable label for the highest badge class based on the user's badge count.

6. **Performance Optimization**: `OPTION (RECOMPILE)` is included to optimize the execution plan based on the specifics of the data retrieved during the query's run.

This query is designed to glean insights into users' engagement with posts and their standing based on badge achievements and interactions.
