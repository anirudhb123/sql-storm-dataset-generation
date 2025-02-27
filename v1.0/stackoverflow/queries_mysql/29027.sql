
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
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
        rp.Body,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(fp.PostId) AS TotalPosts,
        AVGCHAR_LENGTH(fp.Body) AS AvgBodyLength,
        GROUP_CONCAT(fp.Title SEPARATOR '; ') AS TopTitles
    FROM 
        FilteredPosts fp
    JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Tags, '>', numbers.n), '>', -1) AS TagName
         FROM 
             FilteredPosts fp
         JOIN 
             (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
              SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
              SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(fp.Tags) - CHAR_LENGTH(REPLACE(fp.Tags, '>', '')) >= numbers.n - 1
        ) t ON FIND_IN_SET(t.TagName, REPLACE(fp.Tags, '>', ',')) > 0
    GROUP BY 
        t.TagName
)
SELECT 
    ts.TagName,
    ts.TotalPosts,
    ts.AvgBodyLength,
    ts.TopTitles,
    CASE 
        WHEN ts.TotalPosts > 10 THEN 'Active' 
        ELSE 'Less Active' 
    END AS ActivityStatus
FROM 
    TagStatistics ts
ORDER BY 
    ts.TotalPosts DESC;
