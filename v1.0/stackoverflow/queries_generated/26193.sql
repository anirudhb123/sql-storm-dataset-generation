WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_array ON TRUE
    LEFT JOIN 
        Tags t ON tag_array.element = t.TagName
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        *,
        CASE 
            WHEN Score > 10 THEN 'High Score'
            WHEN Score BETWEEN 5 AND 10 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory
    FROM 
        RankedPosts
    WHERE 
        ViewCount > 100
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.CreationDate,
    fp.AnswerCount,
    fp.Score,
    fp.ScoreCategory,
    fp.Tags,
    u.DisplayName AS OwnerName,
    MAX(b.Date) AS LastBadgeDate
FROM 
    FilteredPosts fp
JOIN 
    Users u ON fp.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    b.Class = 1 -- Only Gold badges
GROUP BY 
    fp.PostId, fp.Title, fp.ViewCount, fp.CreationDate, fp.AnswerCount, fp.Score, fp.ScoreCategory, fp.Tags, u.DisplayName
ORDER BY 
    fp.CreationDate DESC, fp.Score DESC
LIMIT 50;
