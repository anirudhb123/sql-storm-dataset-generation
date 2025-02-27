WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY c.CreationDate DESC) AS RecentCommentRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
),

KeywordSearch AS (
    SELECT 
        rp.PostId, 
        rp.Title,
        rp.Body,
        rp.OwnerDisplayName,
        CASE 
            WHEN POSITION('SQL' IN rp.Body) > 0 THEN 'Contains SQL'
            WHEN POSITION('Database' IN rp.Body) > 0 THEN 'Contains Database'
            ELSE 'No relevant keywords'
        END AS KeywordCategory
    FROM 
        RankedPosts rp
)

SELECT 
    k.PostId,
    k.Title,
    k.Body,
    k.OwnerDisplayName,
    k.KeywordCategory,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.ViewCount,
    rp.CommentCount
FROM 
    KeywordSearch k
JOIN 
    RankedPosts rp ON k.PostId = rp.PostId
WHERE 
    k.KeywordCategory != 'No relevant keywords'
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 50;
