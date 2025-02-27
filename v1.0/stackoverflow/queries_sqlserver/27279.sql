
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.CreationDate, 
        p.LastActivityDate, 
        p.ViewCount, 
        p.Score, 
        p.Tags, 
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= '2023-01-01' 
        AND p.Score > 0 
),
PopularTags AS (
    SELECT 
        value AS Tag
    FROM 
        RankedPosts 
    CROSS APPLY STRING_SPLIT(Tags, ',')
),
TagStats AS (
    SELECT 
        pt.Tag, 
        COUNT(*) AS QuestionCount, 
        SUM(rp.Score) AS TotalScore
    FROM 
        PopularTags pt
    JOIN 
        RankedPosts rp ON rp.Tags LIKE '%' + pt.Tag + '%'
    GROUP BY 
        pt.Tag
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.Score,
    ts.Tag,
    ts.QuestionCount,
    ts.TotalScore
FROM 
    RankedPosts rp
JOIN 
    TagStats ts ON rp.Tags LIKE '%' + ts.Tag + '%'
WHERE 
    rp.TagRank <= 3 
ORDER BY 
    ts.TotalScore DESC, 
    rp.ViewCount DESC;
