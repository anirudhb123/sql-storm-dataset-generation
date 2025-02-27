WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostStatistics AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(rp.PostId) AS TotalPosts,
        SUM(CASE WHEN rp.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(rp.ViewCount) AS TotalViews,
        AVG(rp.Score) AS AverageScore,
        SUM(CASE WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) THEN 1 ELSE 0 END) AS TotalUpvotes
    FROM 
        RankedPosts rp
    GROUP BY 
        rp.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.PositivePosts, 0) AS PositivePosts,
    COALESCE(ps.TotalViews, 0) AS TotalViews,
    COALESCE(ps.AverageScore, 0) AS AverageScore,
    COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(phd.EditCount, 0) AS EditCount,
    CASE 
        WHEN COALESCE(ps.PositivePosts, 0) > 0 THEN 'Active Contributor'
        ELSE 'New or Inactive'
    END AS UserActivityStatus
FROM 
    Users u
LEFT JOIN 
    PostStatistics ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryDetails phd ON EXISTS (SELECT 1 FROM Posts p WHERE p.OwnerUserId = u.Id AND p.Id = phd.PostId)
WHERE 
    u.CreationDate < NOW() - INTERVAL '30 days'
ORDER BY 
    u.Reputation DESC NULLS LAST, 
    TotalViews DESC NULLS LAST;

This elaborate SQL query utilizes CTEs for organization, employs window functions for ranking, aggregates data for post statistics and badge information, and applies complex CASE logic to classify user activity status. It joins multiple tables, handles NULL values with COALESCE, and includes intricate conditions to derive metrics within the specified schema.
