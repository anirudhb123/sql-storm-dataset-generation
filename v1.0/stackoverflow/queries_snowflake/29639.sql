
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
        SPLIT(TRIM(BOTH '<>' FROM p.Tags), '><') AS TagsArray
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
TagStats AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagUsageCount
    FROM 
        PostTagCounts,
        LATERAL FLATTEN(input => TagsArray) AS Tag
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
    (SELECT LISTAGG(tt.Tag, ', ') FROM TopTags tt JOIN PostTagCounts pt ON tt.Tag = pt.TagsArray WHERE pt.PostId = rp.PostId) AS PopularTags
FROM 
    RankedPosts rp
WHERE 
    rp.rn = 1  
ORDER BY 
    rp.CreationDate DESC
LIMIT 20;
