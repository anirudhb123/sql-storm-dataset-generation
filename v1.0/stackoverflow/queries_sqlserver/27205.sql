
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.Tags, 
        p.CreationDate, 
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND u.Location IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.OwnerDisplayName, 
        rp.Score,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10  
),
TagFrequency AS (
    SELECT 
        value AS TagName
    FROM 
        TopPosts 
        CROSS APPLY STRING_SPLIT(Tags, '><')
),
TopTags AS (
    SELECT 
        TagName, 
        COUNT(*) AS Frequency
    FROM 
        TagFrequency
    GROUP BY 
        TagName
    ORDER BY 
        Frequency DESC
)
SELECT 
    tt.TagName, 
    COUNT(tp.PostId) AS PostCount, 
    STRING_AGG(tp.OwnerDisplayName, ', ') AS TopOwners
FROM 
    TopTags tt
JOIN 
    TopPosts tp ON tp.Tags LIKE '%' + tt.TagName + '%'
GROUP BY 
    tt.TagName
ORDER BY 
    PostCount DESC;
