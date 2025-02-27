WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.*,
    CAST(AVG(bt.Class) AS decimal(10,2)) AS AverageBadgeClass
FROM 
    TopPosts tp
LEFT JOIN 
    Badges bt ON bt.UserId = (SELECT u.Id FROM Users u WHERE u.DisplayName = tp.OwnerDisplayName)
GROUP BY 
    tp.Title, tp.OwnerDisplayName, tp.Score, tp.ViewCount, tp.CommentCount, tp.AnswerCount
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
