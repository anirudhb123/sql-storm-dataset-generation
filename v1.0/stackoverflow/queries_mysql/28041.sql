
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
), 
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Tags,
        OwnerDisplayName,
        ViewCount,
        Score
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
), 
TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Posts p
    JOIN 
        (SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
             UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
             UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE 
            CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) t ON TRUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        t.TagName
), 
MostUsedTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagUsage
    WHERE 
        PostCount > 100
)
SELECT 
    trp.OwnerDisplayName,
    trp.Title,
    trp.CreationDate,
    trp.ViewCount,
    trp.Score,
    mut.TagName AS MostUsedTag,
    mut.PostCount AS MostUsedTagPostCount
FROM 
    TopRankedPosts trp
JOIN 
    MostUsedTags mut ON trp.Tags LIKE CONCAT('%', mut.TagName, '%')
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
