WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
),
TopVotedPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CreationDate,
        Owner,
        Rank,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 WHEN vt.Name = 'DownMod' THEN -1 ELSE 0 END) AS NetVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        p.Title AS PostTitle,
        COUNT(ph.Id) AS EditCount,
        STRING_AGG(DISTINCT CONCAT_WS(' ', u.DisplayName, ph.Comment), ', ') AS Comments
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        Users u ON ph.UserId = u.Id
    GROUP BY 
        ph.PostId, HistoryDate, p.Title
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CreationDate,
    tp.Owner,
    tp.CommentCount,
    COALESCE(pv.NetVotes, 0) AS NetVotes,
    COALESCE(phd.EditCount, 0) AS EditCount,
    COALESCE(phd.Comments, 'No comments') AS EditComments
FROM 
    TopVotedPosts tp
LEFT JOIN 
    PostVotes pv ON tp.PostId = pv.PostId
LEFT JOIN 
    PostHistoryDetails phd ON tp.PostId = phd.PostId
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
This SQL query constructs a multi-layered analysis on posts created in the last 30 days. It ranks the posts based on their score, computes net votes, tracks edit history, and retrieves comments associated with post edits. It uses CTEs to separate logic for clarity and leverages window functions to enhance performance benchmarking. Finally, it consolidates results while managing NULLs gracefully using COALESCE.
