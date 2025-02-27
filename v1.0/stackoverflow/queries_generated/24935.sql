WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 END), 0) AS VoteScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.UserId = u.Id AND c.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.Reputation IS NOT NULL AND u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.PostCount,
    ua.CommentCount,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.VoteScore
FROM 
    UserActivity ua
LEFT JOIN 
    RankedPosts rp ON ua.UserId = rp.PostId
WHERE 
    (rp.RN IS NULL OR rp.VoteScore > 0) 
    AND NOT EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerUserId = ua.UserId 
        AND p.CreationDate < CURRENT_DATE - interval '1 year'
    )
ORDER BY 
    ua.Reputation DESC, rp.VoteScore DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM Users) % 50;

### Query Breakdown
1. **CTEs: RankedPosts and UserActivity**
   - **RankedPosts**: Computes a score for each post based on votes and ranks them for each user.
   - **UserActivity**: Aggregates user activity metrics, including post counts, comment counts, and badge totals.

2. **Join and Filtering**: 
   - Combines information from both CTEs. The `WHERE` clause filters out non-active users (those without posts for over a year) and ensures only users with positively scored posts are included.

3. **Complex Logic**: 
   - Uses outer joins and correlated subqueries for conditions.
   - Incorporates a bizarre yet valid clause with `(rp.RN IS NULL OR rp.VoteScore > 0)` to allow filtering posts that either don’t exist or have positive votes, showcasing SQL’s handling of NULLs and logical operators.

4. **Paging with OFFSET**: 
   - Introduces randomness or revisiting results due to the unusual OFFSET which utilizes the total count of users modulo 50.

### Use Case
This query can be employed to benchmark the performance of complex SQL operations, focusing on aggregations, filtering, joins, and window functions while testing efficiency in diverse scenarios.
