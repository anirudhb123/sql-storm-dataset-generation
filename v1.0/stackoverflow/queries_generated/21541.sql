WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment = crt.Id::varchar
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId, ph.CreationDate
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.Upvotes,
    rp.Downvotes,
    cb.CloseReasons,
    ub.BadgeCount,
    CASE 
        WHEN ub.BadgeCount IS NULL THEN 'No Badges'
        ELSE CONCAT('Badges: ', ub.BadgeCount, ' (Highest Class: ', 
                    CASE 
                        WHEN ub.HighestBadgeClass = 1 THEN 'Gold'
                        WHEN ub.HighestBadgeClass = 2 THEN 'Silver'
                        ELSE 'Bronze'
                    END, ')')
    END AS BadgeDescription
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    ClosedPosts cb ON rp.PostId = cb.PostId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    rp.UserPostRank <= 3
ORDER BY 
    u.Reputation DESC, 
    rp.Score DESC NULLS LAST;

This SQL query performs a complex analysis of user-generated posts by:

- Utilizing Common Table Expressions (CTEs) to rank posts per user, gather information about closed posts and badge counts for users.
- It applies window functions to partition the data for individual users, counting upvotes and downvotes.
- It applies an outer join to include closed post information, along with a summation of reasons for closure.
- Badge information is aggregated and combined into a descriptive string for each user.
- Finally, the results are filtered to show only the top three posts per user based on their score, ordered by user reputation. 

This showcases various SQL concepts including correlated subqueries, outer joins, window functions, string expressions, NULL logic handling, as well as aggregating and grouping functionally.
