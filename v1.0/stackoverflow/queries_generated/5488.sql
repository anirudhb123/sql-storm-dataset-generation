WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rnk
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Last year
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        CreationDate, 
        Score, 
        OwnerName
    FROM 
        RankedPosts
    WHERE 
        Rnk <= 5 -- Top 5 questions per user
)
SELECT 
    tp.Title, 
    tp.ViewCount, 
    tp.CreationDate, 
    tp.Score, 
    tp.OwnerName,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON b.UserId = (SELECT u.Id FROM Users u WHERE u.DisplayName = tp.OwnerName)
GROUP BY 
    tp.Title, tp.ViewCount, tp.CreationDate, tp.Score, tp.OwnerName
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
