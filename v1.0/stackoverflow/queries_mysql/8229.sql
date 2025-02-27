
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostTypeName,
        COUNT(c.Id) AS CommentTotal,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, pt.Name
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerDisplayName,
    rp.PostTypeName,
    rp.CommentTotal
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.PostTypeName, rp.Score DESC;
