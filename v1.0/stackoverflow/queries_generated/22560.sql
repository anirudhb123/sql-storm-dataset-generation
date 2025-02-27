WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > '2020-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeList,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryInfo AS (
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        MAX(ph.CreationDate) AS LastActionDate 
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)  -- Considering Close, Reopen, and Delete actions
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)

SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    ub.BadgeList,
    ub.BadgeCount,
    (SELECT COUNT(*) FROM PostHistoryInfo phi WHERE phi.PostId = rp.PostId) AS ActionCount,
    CASE 
        WHEN (SELECT COUNT(*) FROM PostHistoryInfo phi WHERE phi.PostId = rp.PostId AND phi.PostHistoryTypeId = 10) > 0 THEN 'Closed'
        WHEN (SELECT COUNT(*) FROM PostHistoryInfo phi WHERE phi.PostId = rp.PostId AND phi.PostHistoryTypeId = 11) > 0 THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.PostId = ub.UserId 
WHERE 
    rp.rn = 1 
ORDER BY 
    rp.Score DESC, 
    rp.UpVotes DESC 
LIMIT 50;
