
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1)) AS TagName
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 
         UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '') ) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
),
TagInteraction AS (
    SELECT 
        r.PostId,
        r.Title,
        r.ViewCount,
        r.AnswerCount,
        r.CreationDate,
        r.OwnerDisplayName,
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS RelatedPostCount
    FROM 
        RankedPosts r
    LEFT JOIN 
        Posts p ON p.ParentId = r.PostId
    JOIN 
        PostTypes pt ON r.Rank = 1 
    GROUP BY 
        r.PostId, r.Title, r.ViewCount, r.AnswerCount, r.CreationDate, r.OwnerDisplayName, pt.Name
)
SELECT 
    ti.PostId,
    ti.Title,
    ti.ViewCount,
    ti.AnswerCount,
    ti.CreationDate,
    ti.OwnerDisplayName,
    ti.PostTypeName,
    ti.RelatedPostCount,
    CASE 
        WHEN ti.ViewCount > 1000 THEN 'High'
        WHEN ti.ViewCount > 500 THEN 'Medium'
        ELSE 'Low'
    END AS PopularityRank
FROM 
    TagInteraction ti
WHERE 
    ti.RelatedPostCount > 0
ORDER BY 
    ti.ViewCount DESC
LIMIT 10;
