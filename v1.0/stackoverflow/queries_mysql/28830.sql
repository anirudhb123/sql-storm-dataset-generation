
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
        p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
        AND p.ViewCount > 100
),
TagStats AS (
    SELECT 
        TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts p
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        Tag
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
    JOIN 
        (SELECT TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS Tag
         FROM Posts p
         INNER JOIN (
            SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
         ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        ) rt ON FIND_IN_SET(rt.Tag, REPLACE(p.Tags, '><', ',')) > 0
    JOIN 
        TopTags tt ON rt.Tag = tt.Tag
    WHERE 
        rp.Rank <= 5 
)

SELECT 
    t.Tag,
    GROUP_CONCAT(CONCAT(tp.OwnerDisplayName, ': ', tp.Title) SEPARATOR '; ') AS TopPosts
FROM 
    TopPostsByTag tp
JOIN 
    TopTags t ON tp.Tag = t.Tag
GROUP BY 
    t.Tag
ORDER BY 
    t.Tag;
