
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
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST(DATEADD(year, -1, '2024-10-01') AS DATE)
),
PopularTags AS (
    SELECT 
        value AS Tag
    FROM 
        RankedPosts
    CROSS APPLY STRING_SPLIT(Tags, '>') 
    WHERE 
        TagRank <= 10 
),
TagPopularity AS (
    SELECT 
        Tag,
        COUNT(*) AS PopularityCount
    FROM 
        PopularTags
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PopularityCount,
        ROW_NUMBER() OVER (ORDER BY PopularityCount DESC) AS PopularityRank
    FROM 
        TagPopularity
    WHERE 
        PopularityCount > 5 
)
SELECT 
    t.Tag,
    t.PopularityCount,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.OwnerDisplayName,
    r.Reputation
FROM 
    TopTags t
JOIN 
    RankedPosts r ON t.Tag IN (SELECT value FROM STRING_SPLIT(r.Tags, '>'))
WHERE 
    t.PopularityRank <= 10 
ORDER BY 
    t.PopularityCount DESC, 
    r.Score DESC;
