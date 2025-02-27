WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
RecentPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes
    FROM 
        PostStats ps
    WHERE 
        ps.rn = 1
    ORDER BY 
        ps.CreationDate DESC
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        pt.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        pht.Name IN ('Post Closed', 'Post Reopened') 
        AND p.CreationDate >= NOW() - INTERVAL '6 months'
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        COALESCE(cp.ClosedDate, 'Not Closed') AS StatusDate,
        COALESCE(cp.CloseReason, 'No Reason') AS CloseReason
    FROM 
        RecentPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.StatusDate,
    pd.CloseReason,
    CASE 
        WHEN pd.CloseReason = 'No Reason' THEN 'Open'
        ELSE 'Closed'
    END AS PostStatus
FROM 
    PostDetails pd
ORDER BY 
    pd.CreationDate DESC
LIMIT 50;
