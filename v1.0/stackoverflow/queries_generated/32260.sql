WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score > 0
),

RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserId,
        u.DisplayName AS EditorName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerName,
    COALESCE(rp.PostRank, 0) AS RankWithinType,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpvoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownvoteCount,
    (SELECT STRING_AGG(pht.Name, ', ') 
     FROM PostHistoryTypes pht 
     WHERE pht.Id IN (SELECT ph.PostHistoryTypeId FROM RecentPostHistory ph WHERE ph.PostId = rp.PostId)) AS RecentChanges,
    ARRAY_AGG(DISTINCT cp.CommentText) AS RecentComments
FROM 
    RankedPosts rp
LEFT JOIN 
    (SELECT c.PostId, c.Text AS CommentText 
     FROM Comments c 
     WHERE c.CreationDate >= NOW() - INTERVAL '30 days') cp ON rp.PostId = cp.PostId
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId AND rph.HistoryRank = 1
WHERE 
    rp.PostRank <= 5
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.OwnerName
ORDER BY 
    rp.Score DESC;

