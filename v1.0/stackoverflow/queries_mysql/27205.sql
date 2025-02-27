
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
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName
    FROM 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
    JOIN 
        TopPosts ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
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
    LIMIT 5  
)
SELECT 
    tt.TagName, 
    COUNT(tp.PostId) AS PostCount, 
    GROUP_CONCAT(tp.OwnerDisplayName) AS TopOwners
FROM 
    TopTags tt
JOIN 
    TopPosts tp ON tp.Tags LIKE CONCAT('%', tt.TagName, '%')
GROUP BY 
    tt.TagName
ORDER BY 
    PostCount DESC;
