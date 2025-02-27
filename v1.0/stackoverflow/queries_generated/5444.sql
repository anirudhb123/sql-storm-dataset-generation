WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions only
        AND p.CreationDate >= NOW() - INTERVAL '7 days'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
),
PostDetails AS (
    SELECT 
        tp.Title,
        tp.OwnerDisplayName,
        tp.ViewCount,
        tp.CommentCount,
        COALESCE(SUM(v.UserId IS NOT NULL AND vt.Id IN (2, 6)), 0) AS UpVotes,
        COALESCE(SUM(v.UserId IS NOT NULL AND vt.Id = 3), 0) AS DownVotes,
        COALESCE(SUM(v.UserId IS NOT NULL AND vt.Id = 10), 0) AS CloseVotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        tp.Title, tp.OwnerDisplayName, tp.ViewCount, tp.CommentCount
)
SELECT 
    pd.Title,
    pd.OwnerDisplayName,
    pd.ViewCount,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.CloseVotes
FROM 
    PostDetails pd
ORDER BY 
    pd.ViewCount DESC, pd.CommentCount DESC;
