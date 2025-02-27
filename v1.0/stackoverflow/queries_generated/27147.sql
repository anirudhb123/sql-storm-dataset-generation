WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(a.Score, 0) AS AnswerScore,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        p.Score AS PostScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT ParentId, SUM(Score) AS Score FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) a ON a.ParentId = p.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.AnswerScore,
    rp.CommentCount,
    rp.PostScore,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') FROM Tags t WHERE t.Id IN (
        SELECT UNNEST(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')::int[])
    )) AS RelatedTags
FROM 
    RankedPosts rp
WHERE 
    rp.RowNum = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 10;
