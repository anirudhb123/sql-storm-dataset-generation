
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(p.AcceptedAnswerId, -1) AS HasAcceptedAnswer,  
        p.Tags,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY 
            CASE 
                WHEN p.PostTypeId = 1 THEN 'Question' 
                ELSE 'Other'
            END 
            ORDER BY 
                p.CreationDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)  
        AND p.Score > 0  
),
UniqueTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        RankedPosts
    CROSS JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
        UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers
    WHERE 
        Tags IS NOT NULL
        AND CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
),
TagFrequency AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        UniqueTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 10  
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.HasAcceptedAnswer,
        rp.ViewCount,
        rp.Score,
        GROUP_CONCAT(DISTINCT tf.Tag) AS PopularTags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TagFrequency tf ON tf.Tag IN (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', numbers.n), '><', -1) 
                                         FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                                               UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
                                               UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
                                         WHERE CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, '><', '')) >= numbers.n - 1)
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.HasAcceptedAnswer, rp.ViewCount, rp.Score
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreationDate,
    CASE WHEN ps.HasAcceptedAnswer = -1 THEN 'No Accepted Answer' ELSE 'Has Accepted Answer' END AS AcceptedAnswer,
    ps.ViewCount,
    ps.Score,
    (LENGTH(ps.PopularTags) - LENGTH(REPLACE(ps.PopularTags, ',', '')) + 1) AS TagCount,
    ps.PopularTags
FROM 
    PostStatistics ps
WHERE 
    (LENGTH(ps.PopularTags) - LENGTH(REPLACE(ps.PopularTags, ',', '')) + 1) > 0  
ORDER BY 
    ps.ViewCount DESC,  
    ps.Score DESC;
