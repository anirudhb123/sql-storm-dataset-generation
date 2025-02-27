WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.Score,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        PERCENT_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment as CloseReason,
        pt.Name AS PostHistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        pt.Name = 'Post Closed'
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
    rp.PostId,
    rp.Title,
    rp.Owner,
    rp.Score,
    rp.CreationDate,
    rp.CommentCount,
    COALESCE(cb.CloseReason, 'Not Closed') AS CloseReason,
    ub.Badges
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cb ON rp.PostId = cb.PostId
LEFT JOIN 
    UserBadges ub ON rp.Owner = ub.UserId
WHERE 
    rp.ScoreRank < 0.1
ORDER BY 
    rp.Score DESC;

