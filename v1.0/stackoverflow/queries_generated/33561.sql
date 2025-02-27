WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        p.CreationDate, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 12) THEN 1 END) AS ClosureCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    pHS.LastClosedDate,
    pHS.LastReopenedDate,
    pHS.ClosureCount,
    ua.UserId,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBadges,
    CASE 
        WHEN pHS.ClosureCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN rp.UpvoteCount IS NULL THEN 0
        ELSE rp.UpvoteCount 
    END AS FinalUpvoteCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistorySummary pHS ON rp.PostId = pHS.PostId
LEFT JOIN 
    UserActivity ua ON rp.OwnerUserId = ua.UserId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
