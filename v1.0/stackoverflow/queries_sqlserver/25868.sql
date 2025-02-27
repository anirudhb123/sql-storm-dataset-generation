
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS Owner,
        COUNT(CASE WHEN c.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN a.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName, p.Tags
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Owner,
        rp.CommentCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 
)
SELECT 
    f.PostId,
    f.Title,
    f.Body,
    f.CreationDate,
    f.ViewCount,
    f.Owner,
    f.CommentCount,
    f.AnswerCount,
    STRING_AGG(DISTINCT t.TagName, ',') AS Tags
FROM 
    FilteredPosts f
LEFT JOIN 
    Posts p ON p.Id = f.PostId 
OUTER APPLY (
    SELECT 
        SUBSTRING(tag, 2, LEN(tag) - 2) AS TagName
    FROM 
        STRING_SPLIT(f.Body, '<tag>')
) AS t 
GROUP BY 
    f.PostId, f.Title, f.Body, f.CreationDate, f.ViewCount, f.Owner, f.CommentCount, f.AnswerCount
ORDER BY 
    f.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
