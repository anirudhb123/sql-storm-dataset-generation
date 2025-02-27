WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 50
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(pt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        pt.Name IN ('Post Closed', 'Post Reopened')
    GROUP BY 
        ph.PostId, ph.CreationDate
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeType
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ru.PostId,
    ru.Title,
    ru.CreationDate,
    ru.ViewCount,
    ru.Score AS PostScore,
    tu.DisplayName AS Owner,
    tu.TotalScore,
    tu.PostCount,
    cb.CloseReasons,
    ub.BadgeCount,
    CASE 
        WHEN ub.HighestBadgeType = 1 THEN 'Gold'
        WHEN ub.HighestBadgeType = 2 THEN 'Silver'
        WHEN ub.HighestBadgeType = 3 THEN 'Bronze'
        ELSE 'None'
    END AS HighestBadge
FROM 
    RankedPosts ru
JOIN 
    TopUsers tu ON ru.OwnerUserId = tu.UserId
LEFT JOIN 
    ClosedPosts cb ON ru.PostId = cb.PostId
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
WHERE 
    ru.Rank <= 5
    AND (ru.Score >= 10 OR ru.ViewCount > 100)
ORDER BY 
    ru.ViewCount DESC, tu.TotalScore DESC, cb.CreationDate DESC
LIMIT 100;

### Explanation of the query components:

1. **Common Table Expressions (CTEs)**
   - `RankedPosts`: Computes rankings of posts per user based on score and creation date over the past year.
   - `TopUsers`: Aggregates user information who have a reputation greater than 50, summing their posts' scores and counts.
   - `ClosedPosts`: Gathers information about post histories related to closing and reopening posts, aggregating the reasons.
   - `UserBadges`: Counts badges for users and finds the highest class of badge.

2. **Main Query**
   - Joins several datasets: the ranked posts, top users, closed posts, and user badges to present a comprehensive view.
   - Uses filtering based on rank, score, and view count.
   - Uses case statements to convert numeric values related to badges into human-readable strings.

3. **Filtering and Ordering**
   - Applies advanced filtering to highlight the top-ranking posts and sort them based on their view count and total score.

4. **Aggregations and String Functions**
   - `STRING_AGG` is used to concatenate the close reasons for a post, showcasing an advanced application of aggregations.

### Conclusion
This elaborate query serves as a performance benchmark by demonstrating complex constructs such as CTEs, window functions, aggregations, correlated relationships, and complex predicates, making it suitable for testing SQL execution efficiency under challenging scenarios.
