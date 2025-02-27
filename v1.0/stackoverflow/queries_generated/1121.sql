WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)::int) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)::int) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score > 0
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    cp.UserDisplayName AS ClosedBy,
    cp.CreationDate AS ClosedDate,
    CASE 
        WHEN cp.Comment IS NOT NULL THEN 'Closed: ' || cp.Comment
        ELSE 'Closed Without Reason'
    END AS ClosureReason
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC
LIMIT 100;
