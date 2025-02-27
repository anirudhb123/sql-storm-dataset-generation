
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
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS rnk
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag_name
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
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
LIMIT 10;
