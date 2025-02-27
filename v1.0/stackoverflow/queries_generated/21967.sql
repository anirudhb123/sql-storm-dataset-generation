WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        U.Reputation AS OwnerReputation,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upvotes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR' 
        AND (p.Title IS NOT NULL AND LENGTH(p.Title) > 0)
    GROUP BY 
        p.Id, U.Reputation
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
    GROUP BY 
        ph.PostId, ph.CreationDate
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CommentCount,
    rp.RankScore,
    CASE 
        WHEN cp.LastClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open' 
    END AS PostStatus,
    COALESCE(ub.TotalBadges, 0) AS UserBadgeCount,
    COALESCE(ub.BadgeNames, 'No Badges') AS UserBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerReputation = ub.UserId
WHERE 
    rp.RankScore <= 5
ORDER BY 
    rp.RankScore, rp.Score DESC;


This SQL query performs performance benchmarking by:

1. **CTEs**: It uses Common Table Expressions (CTEs) to calculate rankings of posts based on score, closed post statuses, and user badge counts separately before combining them.
2. **Window Function**: Applies a window function (`RANK()`) to determine rankings of posts within each post type.
3. **Aggregations**: Utilizes `COUNT` for comment counts and distinct vote counts.
4. **String Aggregation**: Includes `STRING_AGG` to compile badge names into a single string list for each user.
5. **NULL Handling**: Uses `COALESCE` to handle potential NULL values when users have zero badges.
6. **Pattern Checks**: Contains predicates to filter out unwanted titles and results, including checks for closed posts.
7. **Order By**: Finally orders results to display the highest-ranked posts first.

This complex query serves as a practical example for performance benchmarking while exploring various SQL constructs and edge cases.
