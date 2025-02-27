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
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.Score, u.DisplayName
), 
PostTagCounts AS (
    SELECT 
        PostId, 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only questions
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
    LIMIT 10  -- Top 10 tags
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    (SELECT STRING_AGG(Tag, ', ') FROM TopTags tt JOIN PostTagCounts pt ON tt.Tag = pt.Tag WHERE pt.PostId = rp.PostId) AS PopularTags
FROM 
    RankedPosts rp
WHERE 
    rp.rn = 1  -- Select the latest posts
ORDER BY 
    rp.CreationDate DESC
LIMIT 20;  -- Limit to the latest 20 questions
