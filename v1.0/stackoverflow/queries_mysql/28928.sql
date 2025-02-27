
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostTypeName,
        RANK() OVER (PARTITION BY pt.Id ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR AND 
        p.Score > 0
),
RelevantTags AS (
    SELECT 
        PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        RankedPosts
    JOIN 
        (
            SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
            SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
            SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL 
            SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL 
            SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 
        ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagFrequency
    FROM 
        RelevantTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5
),
TopPosts AS (
    SELECT 
        r.* 
    FROM 
        RankedPosts r
    JOIN 
        TagCounts tc ON r.Tags LIKE CONCAT('%<', tc.Tag, '>%')
    WHERE 
        r.RankScore <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.PostTypeName,
    GROUP_CONCAT(DISTINCT tc.Tag SEPARATOR ', ') AS RelatedTags
FROM 
    TopPosts tp
JOIN 
    RelevantTags rt ON tp.PostId = rt.PostId
JOIN 
    TagCounts tc ON rt.Tag = tc.Tag
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerDisplayName, tp.PostTypeName
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
