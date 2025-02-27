WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    AND 
        p.PostTypeId IN (1, 2)
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.OwnerDisplayName,
        tp.Score,
        tp.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        TopPosts tp
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON tp.PostId = c.PostId
    LEFT JOIN (
        SELECT 
            ParentId AS PostId, 
            COUNT(*) AS AnswerCount 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) a ON tp.PostId = a.PostId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON tp.OwnerDisplayName = b.UserId
)
SELECT 
    pd.*, 
    pht.Name AS PostHistoryType
FROM 
    PostDetails pd
JOIN 
    PostHistory ph ON pd.PostId = ph.PostId
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id 
WHERE 
    ph.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
