WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Upvotes and Downvotes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.OwnerUserId, p.CreationDate
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS FirstCloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS LastCloseDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS EditCount,
        MAX(ph.UserDisplayName) AS LastEditor
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),

UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    up.DisplayName AS UserDisplayName,
    rp.Title,
    rp.Score,
    rp.VoteCount,
    COALESCE(phd.FirstCloseDate, 'No Closure') AS FirstClose,
    COALESCE(phd.LastCloseDate, 'Not Reopened') AS LastClose,
    ub.BadgeNames,
    ub.BadgeCount,
    CASE 
        WHEN rp.UserRank = 1 THEN 'Top Post'
        WHEN rp.UserRank <= 3 THEN 'High Performer'
        ELSE 'Average Performer' 
    END AS PerformanceRank
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
WHERE 
    rp.Score IS NOT NULL 
    AND rp.VoteCount > 0
    AND (rp.Score > 10 OR rp.CreationDate < NOW() - INTERVAL '6 months')
ORDER BY 
    rp.Score DESC,
    up.Reputation DESC
LIMIT 100;

This query combines multiple advanced SQL constructs, such as Common Table Expressions (CTEs), window functions, and aggregation. It consolidates data about posts, their owners, their voting history, their editing history, and even user badges, providing an extensive overview of post and user performance over the last year. The semantic nuances incorporate considerations for closures, rankings based on score and editing frequency, and the classification of user engagement based on their contributions and achievements.
