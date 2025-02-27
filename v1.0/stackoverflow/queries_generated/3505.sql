WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerDisplayName,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId) c ON rp.PostId = c.PostId
    LEFT JOIN 
        (SELECT 
            UserId, 
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId) b ON rp.OwnerDisplayName = b.UserId
    WHERE 
        rp.Rank <= 5 -- Top 5 posts per user
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Only close, reopen, and delete actions
    GROUP BY 
        ph.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.CreationDate,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.BadgeCount,
    COALESCE(phc.HistoryCount, 0) AS PostHistoryCount,
    CASE 
        WHEN ps.Score >= 100 THEN 'High Score'
        WHEN ps.Score BETWEEN 50 AND 99 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    CASE 
        WHEN ps.CreationDate < NOW() - INTERVAL '1 year' THEN 'Older Post'
        ELSE 'Recent Post'
    END AS PostAge
FROM 
    PostStats ps
LEFT JOIN 
    PostHistoryCounts phc ON ps.PostId = phc.PostId
ORDER BY 
    ps.Score DESC, ps.CommentCount DESC;
