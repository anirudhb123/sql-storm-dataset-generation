
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= '2023-10-01 12:34:56' - INTERVAL 1 YEAR
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
        AND CreationDate >= '2023-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    pt.TagName,
    rp.TagRank
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.Tags LIKE CONCAT('%', pt.TagName, '%')
WHERE 
    rp.TagRank <= 5
ORDER BY 
    rp.ViewCount DESC, 
    rp.OwnerReputation DESC;
