WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)   -- Considering only Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerName,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)

SELECT 
    tp.*, 
    CASE 
        WHEN b.UserId IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS HasBadge
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON tp.OwnerName = (SELECT DisplayName FROM Users WHERE Id = b.UserId) 
              AND b.Class = 1  -- Only Gold badges
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
