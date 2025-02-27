WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.LastActivityDate,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL AND 
        p.ViewCount > 10
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyAmount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS TotalChanges,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS ClosedOrReopened,
        MAX(CASE WHEN ph.PostHistoryTypeId = 9 THEN 1 ELSE 0 END) AS RollbackTags
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    p.PostId,
    p.Title,
    p.Score,
    (SELECT MAX(ClosedOrReopened) FROM PostHistorySummary phs WHERE phs.PostId = p.PostId) AS PostClosureStatus,
    ua.TotalPosts,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    COALESCE(ub.Badges, 'No Badges') AS UserBadges,
    CASE 
        WHEN r.Rank <= 5 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts r
JOIN 
    Posts p ON r.PostId = p.Id
JOIN 
    UserActivity ua ON p.OwnerUserId = ua.UserId
LEFT JOIN 
    UserBadges ub ON p.OwnerUserId = ub.UserId
WHERE 
    ua.TotalPosts > 0
ORDER BY 
    p.Score DESC, 
    p.LastActivityDate DESC;

-- This query retrieves ranked posts with user activity and post history details,
-- along with aggregated data about badges earned by the post owners.
