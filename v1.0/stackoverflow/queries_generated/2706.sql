WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, u.DisplayName
), 
TopPosts AS (
    SELECT 
        Id, 
        Title, 
        OwnerName,
        CommentCount, 
        UpVotes, 
        DownVotes 
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
), 
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS CloseDate, 
        cr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    tp.Title,
    tp.OwnerName,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    COALESCE(cp.CloseDate, 'Not Closed') AS CloseDate,
    COALESCE(cp.CloseReason, 'N/A') AS CloseReason
FROM 
    TopPosts tp
LEFT JOIN 
    ClosedPosts cp ON tp.Id = cp.PostId
ORDER BY 
    tp.UpVotes DESC, tp.CommentCount DESC;
