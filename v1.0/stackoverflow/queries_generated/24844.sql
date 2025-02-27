WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId IN (2, 6)) AS TotalUpvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId IN (3, 10)) AS TotalDownvotes,
        COUNT(DISTINCT p.Id) AS TotalPostsCreated,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON v.UserId = u.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY u.Id
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpvotes, -- Upvotes on post
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS TotalDownvotes -- Downvotes on post
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    GROUP BY p.Id
),
RankedPosts AS (
    SELECT 
        pm.PostId,
        ROW_NUMBER() OVER (PARTITION BY pm.OwnerUserId ORDER BY pm.TotalUpvotes DESC) AS PostRank,
        pm.TotalUpvotes,
        pm.TotalDownvotes,
        CASE 
            WHEN pm.TotalUpvotes > pm.TotalDownvotes THEN 'Positive' 
            WHEN pm.TotalDownvotes > pm.TotalUpvotes THEN 'Negative' 
            ELSE 'Neutral' 
        END AS Sentiment
    FROM PostMetrics pm
),
TopBadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.TotalUpvotes
    FROM Users u
    INNER JOIN UserVoteStats ub ON u.Id = ub.UserId
    WHERE ub.TotalUpvotes > 50
)
SELECT 
    u.DisplayName,
    ub.TotalPostsCreated,
    ub.TotalUpvotes,
    ub.TotalDownvotes,
    b.GoldBadges,
    b.SilverBadges,
    b.BronzeBadges,
    rp.PostId,
    rp.PostRank,
    rp.TotalUpvotes AS PostUpvotes,
    rp.TotalDownvotes AS PostDownvotes,
    rp.Sentiment
FROM UserVoteStats ub
JOIN TopBadgedUsers u ON ub.UserId = u.UserId
JOIN RankedPosts rp ON rp.OwnerUserId = ub.UserId
LEFT JOIN Badges b ON b.UserId = u.UserId
WHERE u.Reputation > 1000
  AND (ub.TotalUpvotes - ub.TotalDownvotes) > 10
ORDER BY u.DisplayName, rp.PostRank
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;

### Explanation of the Query:
1. **Common Table Expressions (CTEs)**: 
   - `UserVoteStats`: Calculate total upvotes, downvotes, and badges for each user.
   - `PostMetrics`: Aggregate metrics for each post, including the number of comments and vote counts.
   - `RankedPosts`: Rank posts for each user based on total upvotes and classify them as 'Positive', 'Negative', or 'Neutral'.
   - `TopBadgedUsers`: Filter users who have more than 50 total upvotes.

2. **Joins**: Various joins are used to connect users, posts, votes, and badges.

3. **Conditional Logic**: The sentiment of posts is determined based on vote counts, and further conditions filter the results based on user reputation and vote differences.

4. **Window Functions**: The `ROW_NUMBER()` window function is used to rank posts for each user.

5. **Pagination**: The use of `OFFSET ... FETCH NEXT` allows for pagination of results.

6. **Aggregate Functions**: Use of `COUNT`, `SUM`, and `COALESCE` to handle potential null values appropriately.

This query provides a rich dataset suitable for performance benchmarking, including various SQL constructs and logic.
