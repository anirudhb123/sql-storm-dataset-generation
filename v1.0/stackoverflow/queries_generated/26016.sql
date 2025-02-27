WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS LatestPostRowNum
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),

FilteredPosts AS (
    SELECT 
        rp.*,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        RankedPosts rp
    LEFT JOIN 
        STRING_TO_ARRAY(rp.Tags, '><') AS tagArray ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tagArray
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Body, rp.ViewCount, rp.AnswerCount, rp.Score, rp.Tags, rp.OwnerDisplayName
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.AnswerCount,
    fp.OwnerDisplayName,
    fp.TagList,
    CASE 
        WHEN fp.PostRank = 1 THEN 'Top Post'
        ELSE 'Other Post'
    END AS PostCategory,
    COALESCE(SUM(ph.UserId IS NOT NULL), 0) AS TotalEdits,
    COUNT(c.Id) AS CommentCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistory ph ON fp.PostId = ph.PostId 
LEFT JOIN 
    Comments c ON c.PostId = fp.PostId
WHERE 
    fp.LatestPostRowNum = 1
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.Score, fp.ViewCount, fp.AnswerCount, fp.OwnerDisplayName, fp.TagList, fp.PostRank
ORDER BY 
    fp.Score DESC
LIMIT 50;
