
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
), PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS TagName,
        COUNT(*) AS Count
    FROM 
        RankedPosts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    GROUP BY 
        TagName
    ORDER BY 
        Count DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.Score,
    pt.TagName AS PopularTag,
    rp.TagRank
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON pt.TagName = SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, ',', numbers.n), ',', -1)
JOIN 
    (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
     UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, ',', '')) >= numbers.n - 1
WHERE 
    rp.Score > 0 
ORDER BY 
    pt.Count DESC, 
    rp.Score DESC, 
    rp.TagRank ASC;
