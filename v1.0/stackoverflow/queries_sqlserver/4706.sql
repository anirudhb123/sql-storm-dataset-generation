
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        ISNULL(u.DisplayName, 'Anonymous') AS Owner
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.Rank <= 5
),
CommentsSummary AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.ViewCount,
        tp.Score,
        cs.CommentCount,
        cs.LastCommentDate,
        CASE 
            WHEN cs.CommentCount > 5 THEN 'Highly Discussed'
            WHEN cs.CommentCount BETWEEN 3 AND 5 THEN 'Moderately Discussed'
            ELSE 'Less Discussed'
        END AS DiscussionType
    FROM 
        TopPosts tp
    LEFT JOIN 
        CommentsSummary cs ON tp.PostId = cs.PostId
)
SELECT 
    pd.*,
    ISNULL(ph.Comment, 'No history available') AS PostHistoryComment
FROM 
    PostDetails pd
LEFT JOIN 
    PostHistory ph ON pd.PostId = ph.PostId AND ph.PostHistoryTypeId = 10
WHERE 
    pd.Score > (
        SELECT AVG(Score) FROM Posts
    )
ORDER BY 
    pd.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
