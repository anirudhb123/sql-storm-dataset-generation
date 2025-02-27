
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
        AND p.PostTypeId = 1
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerDisplayName
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC;
