
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS rnk
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS APPLY 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS tag_name
    LEFT JOIN 
        Tags t ON t.TagName = tag_name.value
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Score, p.ViewCount, p.CreationDate, p.OwnerUserId, u.DisplayName
), 
FilteredPosts AS (
    SELECT 
        *,
        AVG(rnk) OVER () AS AvgRank
    FROM 
        RankedPosts
    WHERE 
        ViewCount > (SELECT AVG(ViewCount) FROM Posts WHERE PostTypeId = 1)  
)
SELECT 
    PostID,
    Title,
    Body,
    Score,
    ViewCount,
    CreationDate,
    OwnerDisplayName,
    CommentCount,
    Tags,
    CASE 
        WHEN Score > AvgRank THEN 'Above Average'
        ELSE 'Below Average'
    END AS ScoreEvaluation
FROM 
    FilteredPosts
ORDER BY 
    Score DESC, CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
