WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.UpVotes,
    pd.DownVotes,
    pd.CommentCount,
    cp.ClosedDate,
    cp.CloseReason
FROM 
    PostDetails pd
LEFT JOIN 
    ClosedPosts cp ON pd.PostId = cp.Id
WHERE 
    pd.ScoreRank = 1
ORDER BY 
    pd.UpVotes DESC, pd.CommentCount DESC NULLS LAST
