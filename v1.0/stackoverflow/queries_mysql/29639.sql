
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.Tags, 
        p.CreationDate, 
        p.Score, 
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId 
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.Score, u.DisplayName
), 
PostTagCounts AS (
    SELECT 
        p.Id AS PostId, 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT a.N + 1 AS n FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS a) n
    ON LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) >= n.n
    WHERE 
        p.PostTypeId = 1  
),
TagStats AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagUsageCount
    FROM 
        PostTagCounts
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag
    FROM 
        TagStats
    ORDER BY 
        TagUsageCount DESC
    LIMIT 10  
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    (SELECT GROUP_CONCAT(tt.Tag SEPARATOR ', ') FROM TopTags tt JOIN PostTagCounts pt ON tt.Tag = pt.Tag WHERE pt.PostId = rp.PostId) AS PopularTags
FROM 
    RankedPosts rp
WHERE 
    rp.rn = 1  
ORDER BY 
    rp.CreationDate DESC
LIMIT 20;
