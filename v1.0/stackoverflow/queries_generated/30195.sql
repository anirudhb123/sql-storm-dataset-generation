WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.Reputation,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
PostComments AS (
    SELECT 
        pc.PostId,
        COUNT(pc.Id) AS CommentCount,
        MAX(pc.CreationDate) AS LatestCommentDate
    FROM 
        Comments pc
    GROUP BY 
        pc.PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Reputation,
        rp.OwnerDisplayName,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(pc.LatestCommentDate, '1900-01-01') AS LatestCommentDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    WHERE 
        rp.Rank <= 5 -- Top 5 posts per user
),
PostHistoryFiltered AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, '; ') AS RecentChanges,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= date_trunc('year', CURRENT_DATE - INTERVAL '1 year') -- Last year changes
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.Reputation,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.LatestCommentDate,
    ph.RecentChanges,
    ph.ChangeCount,
    CASE 
        WHEN tp.LatestCommentDate IS NULL THEN 'No Comments'
        ELSE TO_CHAR(tp.LatestCommentDate, 'YYYY-MM-DD HH24:MI:SS')
    END AS LatestCommentFormatted
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistoryFiltered ph ON tp.PostId = ph.PostId
ORDER BY 
    tp.Score DESC, tp.Reputation DESC
LIMIT 20;
