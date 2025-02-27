WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2) -- Interested in Questions and Answers
),
TopPosts AS (
    SELECT 
        rp.*
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.OwnerName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(h.Count, 0) AS CommentCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS Count FROM Comments GROUP BY PostId) h ON tp.PostId = h.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.OwnerName
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.OwnerName,
    pd.UpVotes,
    pd.DownVotes,
    pd.CommentCount
FROM 
    PostDetails pd
ORDER BY 
    pd.CreationDate DESC;
