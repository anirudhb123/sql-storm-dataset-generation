WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        c.PostId
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        STRING_AGG(h.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes h ON ph.PostHistoryTypeId = h.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.PostRank,
    rp.UserReputation,
    COALESCE(rc.CommentCount, 0) AS CommentCount,
    COALESCE(rc.LastCommentDate, 'No Comments') AS LastCommentDate,
    ph.HistoryTypes
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentComments rc ON rp.PostId = rc.PostId
LEFT JOIN 
    PostHistoryInfo ph ON rp.PostId = ph.PostId
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.PostRank, rp.Score DESC;
