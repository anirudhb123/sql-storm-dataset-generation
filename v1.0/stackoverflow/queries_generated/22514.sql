WITH PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.Title,
        CASE 
            WHEN p.ViewCount IS NULL THEN 0 
            ELSE p.ViewCount * 1.5 
        END AS AdjustedViewCount
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId, p.PostTypeId, p.Title, p.ViewCount
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges,
        COALESCE(SUM(pa.CommentCount), 0) AS TotalComments,
        COALESCE(SUM(pa.AdjustedViewCount), 0) AS TotalAdjustedViews
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    LEFT JOIN PostActivity pa ON pa.OwnerUserId = u.Id
    WHERE u.Reputation > 1000 OR (u.CreationDate > NOW() - INTERVAL '1 month' AND u.Reputation > 0)
    GROUP BY u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.PostCount,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    ua.TotalComments,
    ua.TotalAdjustedViews,
    CASE 
        WHEN u.TotalAdjustedViews IS NULL THEN 'No Activity'
        WHEN u.TotalAdjustedViews > 1000 THEN 'Highly Engaged'
        ELSE 'Moderately Engaged'
    END AS EngagementLevel
FROM UserActivity ua
FULL OUTER JOIN (
    SELECT 
        UserId,
        SUM(AdjustedViewCount) AS TotalAdjustedViews
    FROM PostActivity
    GROUP BY UserId
) u ON ua.UserId = u.UserId
ORDER BY ua.Reputation DESC NULLS LAST, ua.PostCount DESC;

This SQL query performs a complex performance benchmarking task that incorporates various SQL constructs, including Common Table Expressions (CTEs), outer joins, correlated subqueries, grouping, and window functions. The query does the following:

1. **PostActivity CTE**: Aggregates posts created within the last year, counting comments and up/down votes, while calculating an adjusted view count.

2. **UserActivity CTE**: Aggregates data across users, summarizing their posts, badge counts, and linking back to the PostActivity CTE for total views and comments.

3. A final selection retrieves user information, categorically defining their engagement level based on total adjusted views, and performing a full outer join with total adjusted views from PostActivity.

4. The use of complex predicates, including conditional logic around NULL values and filters based on reputation and creation date, adds depth to the analysis.

5. The result set is ordered prioritizing users with higher reputation and post counts.
