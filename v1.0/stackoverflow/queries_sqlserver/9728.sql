
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p 
    JOIN 
        Users u ON p.OwnerUserId = u.Id 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        STRING_SPLIT(p.Tags, '><') AS t ON 1=1
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, u.DisplayName, p.Tags
), FilteredPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.rn = 1
)
SELECT 
    fp.Id, 
    fp.Title, 
    fp.Score, 
    fp.ViewCount, 
    fp.AnswerCount, 
    fp.CommentCount, 
    fp.OwnerDisplayName, 
    fp.TagsList
FROM 
    FilteredPosts fp
WHERE 
    fp.Score > 10 
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
