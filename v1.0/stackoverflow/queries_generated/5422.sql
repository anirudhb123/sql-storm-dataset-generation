WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankWithinType
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        Score, 
        OwnerDisplayName, 
        CommentCount, 
        VoteCount
    FROM 
        RankedPosts 
    WHERE 
        RankWithinType <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.VoteCount,
    COALESCE(b.Date, 'No Badge') AS LastBadgeDate,
    COUNT(DISTINCT ph.Id) AS HistoryChangeCount
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId) 
LEFT JOIN 
    PostHistory ph ON ph.PostId = tp.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.ViewCount, tp.Score, tp.OwnerDisplayName, tp.CommentCount, tp.VoteCount, b.Date
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
