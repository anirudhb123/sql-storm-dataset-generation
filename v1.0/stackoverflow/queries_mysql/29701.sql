
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
        AND p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1) AS Tag
    FROM 
        RankedPosts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1
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
    RankedPosts r ON FIND_IN_SET(t.Tag, REPLACE(r.Tags, '>', ',')) > 0
WHERE 
    t.PopularityRank <= 10 
ORDER BY 
    t.PopularityCount DESC, 
    r.Score DESC;
