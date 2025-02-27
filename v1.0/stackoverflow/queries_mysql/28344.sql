
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT f.Tags), ',', n.n), ',', -1) AS TagName
    FROM 
        FilteredPosts f
    JOIN 
        (SELECT a.N + b.N * 10 AS n
         FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS a
         CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS b
        ) n 
    WHERE 
        n.n <= LENGTH(GROUP_CONCAT(DISTINCT f.Tags)) - LENGTH(REPLACE(GROUP_CONCAT(DISTINCT f.Tags), ',', '')) + 1
    GROUP BY n.n
),
TagFrequency AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount
    FROM 
        PopularTags
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10 
)
SELECT 
    tf.TagName,
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.Score
FROM 
    TagFrequency tf
JOIN 
    FilteredPosts fp ON FIND_IN_SET(tf.TagName, fp.Tags)
ORDER BY 
    tf.PostCount DESC, 
    fp.Score DESC;
