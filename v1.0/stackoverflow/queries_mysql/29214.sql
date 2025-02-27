
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        @row_number := IF(@prev_tag = p.Tags, @row_number + 1, 1) AS TagRank,
        @prev_tag := p.Tags,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_tag := '') AS vars
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    CASE 
        WHEN rp.TagRank = 1 THEN 'Top Post in Tag'
        WHEN rp.TagRank <= 5 THEN 'Popular Post in Tag'
        ELSE 'Other Posts'
    END AS PostRanking
FROM 
    RankedPosts rp
WHERE 
    rp.CommentCount > 0 
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;
