
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND  
        p.Body IS NOT NULL
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        Author,
        CreationDate,
        Score
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5  
),
TagCounts AS (
    SELECT 
        TRIM(tag) AS TagName,
        COUNT(*) AS Count
    FROM 
        FilteredPosts,
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Tags, ',', numbers.n), ',', -1)) AS tag
        FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
        WHERE CHAR_LENGTH(fp.Tags) - CHAR_LENGTH(REPLACE(fp.Tags, ',', '')) >= numbers.n - 1) as numbers
    GROUP BY 
        TRIM(tag)
),
PopularTags AS (
    SELECT 
        TagName,
        Count,
        DENSE_RANK() OVER (ORDER BY Count DESC) AS TagRank
    FROM 
        TagCounts
)
SELECT 
    pt.TagName,
    pt.Count AS TagUsageCount,
    fp.Author,
    COUNT(fp.PostId) AS NumberOfPosts,
    SUM(fp.Score) AS TotalScore
FROM 
    PopularTags pt
JOIN 
    FilteredPosts fp ON FIND_IN_SET(pt.TagName, fp.Tags)
WHERE 
    pt.TagRank <= 10  
GROUP BY 
    pt.TagName, pt.Count, fp.Author
ORDER BY 
    TagUsageCount DESC, TotalScore DESC;
