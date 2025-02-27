WITH RecursivePostHistories AS (
    SELECT 
        ph.Id, 
        ph.PostId, 
        ph.PostHistoryTypeId, 
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'  -- Only consider posts edited in the last year
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        AVG(c.Score) AS AvgCommentScore
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '6 months' -- Recent posts
    GROUP BY 
        p.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPostsCount,
        SUM(b.Class) AS TotalBadgePoints
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Date >= NOW() - INTERVAL '1 year' -- Badges obtained in the last year
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        rp.ViewCount,
        u.DisplayName,
        u.Reputation,
        u.UpvotedPostsCount,
        u.TotalBadgePoints,
        CASE 
            WHEN rh.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
            WHEN rh.Comment IS NULL THEN 'No Comments'
            ELSE 'Edited'
        END AS PostState,
        rph.creationDate AS LastEditTime
    FROM 
        RecentPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        RecursivePostHistories rph ON rp.PostId = rph.PostId AND rph.rn = 1  -- Latest post history edit
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.DisplayName,
    ps.Reputation,
    ps.UpvotedPostsCount,
    ps.TotalBadgePoints,
    ps.PostState,
    ps.LastEditTime,
    CASE 
        WHEN ps.Reputation IS NULL THEN 'No Reputation'
        ELSE 'Has Reputation'
    END AS ReputationStatus
FROM 
    PostStatistics ps
WHERE 
    ps.Score = (SELECT MAX(Score) FROM Posts)  -- Fetch top score posts
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;
