WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.PostTypeId,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostDetail AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.PostTypeId,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.PostTypeId, tp.CreationDate, tp.Score, tp.ViewCount
)
SELECT 
    pd.*,
    pt.Name AS PostTypeName,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    COUNT(DISTINCT ph.Id) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseRevisions
FROM 
    PostDetail pd
JOIN 
    PostTypes pt ON pd.PostTypeId = pt.Id
LEFT JOIN 
    Badges b ON pd.PostId = b.UserId
LEFT JOIN 
    PostHistory ph ON pd.PostId = ph.PostId
GROUP BY 
    pd.PostId, pd.Title, pd.PostTypeId, pd.CreationDate, pd.Score, pd.ViewCount, pt.Name
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
