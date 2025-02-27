WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name,
        b.Date,
        DENSE_RANK() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Badges b
    WHERE 
        b.Date >= CURRENT_DATE - INTERVAL '1 year'
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
UserPostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(ub.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(c.FirstClosedDate, NULL) AS ClosedDate,
    upv.UpVotes,
    upv.DownVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    PostComments pc ON rp.Id = pc.PostId
LEFT JOIN 
    RecentBadges rb ON rp.OwnerUserId = rb.UserId AND rb.BadgeRank = 1
LEFT JOIN 
    ClosedPosts c ON rp.Id = c.PostId
LEFT JOIN 
    (SELECT COUNT(*) AS BadgeCount, UserId FROM Badges GROUP BY UserId) ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    UserPostVotes upv ON rp.Id = upv.PostId
WHERE 
    rp.RN = 1
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 100;
