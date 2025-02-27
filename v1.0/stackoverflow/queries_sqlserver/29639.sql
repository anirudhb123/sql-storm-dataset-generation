
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
        value AS Tag
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS value
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
    SELECT TOP 10 
        Tag
    FROM 
        TagStats
    ORDER BY 
        TagUsageCount DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    (SELECT STRING_AGG(tt.Tag, ', ') FROM TopTags tt JOIN PostTagCounts pt ON tt.Tag = pt.Tag WHERE pt.PostId = rp.PostId) AS PopularTags
FROM 
    RankedPosts rp
WHERE 
    rp.rn = 1  
ORDER BY 
    rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
