
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY 
            CASE 
                WHEN p.PostTypeId = 1 THEN 'Question'
                WHEN p.PostTypeId = 2 THEN 'Answer'
                ELSE 'Other'
            END 
            ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
        AND p.ViewCount > 100
),
TagStats AS (
    SELECT 
        TRIM(REPLACE(REPLACE(value, '<', ''), '>', '')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, '><') AS value
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TRIM(REPLACE(REPLACE(value, '<', ''), '>', ''))
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStats
    WHERE 
        PostCount > 5 
),

TopPostsByTag AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Rank,
        rt.Tag
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostID = p.Id
    CROSS APPLY STRING_SPLIT(p.Tags, '><') AS rt(Tag)
    JOIN 
        TopTags tt ON rt.Tag = tt.Tag
    WHERE 
        rp.Rank <= 5 
)

SELECT 
    t.Tag,
    STRING_AGG(tp.OwnerDisplayName + ': ' + tp.Title, '; ') AS TopPosts
FROM 
    TopPostsByTag tp
JOIN 
    TopTags t ON tp.Tag = t.Tag
GROUP BY 
    t.Tag
ORDER BY 
    t.Tag;
