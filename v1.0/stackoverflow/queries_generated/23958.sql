WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
        AND p.Score > 0
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
RecentClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId, ph.CreationDate
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Rank,
        ua.PostsCount,
        ua.CommentsCount,
        ua.TotalBounties,
        rcp.CloseReasons
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserActivity ua ON rp.PostId = ua.UserId
    LEFT JOIN 
        RecentClosedPosts rcp ON rp.PostId = rcp.PostId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.Rank,
    pm.PostsCount,
    pm.CommentsCount,
    pm.TotalBounties,
    COALESCE(pm.CloseReasons, 'No close reasons') AS CloseReasons
FROM 
    PostMetrics pm
ORDER BY 
    pm.Rank, pm.PostId DESC
LIMIT 50;

-- Corner case: Normalizing the CloseReasons. If the post is closed and has no associated reason, we mark it explicitly.
-- Keep in mind:
-- 1. Count of posts by each user, along with counts of their comments and total bounties they have received or given.
-- 2. Posts that have been closed, regardless of whether they are still visible or in the process of being reopened.
-- 3. A mix of aggregate metrics and detailed rankings can provide a more comprehensive overview for performance benchmarking.
