
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY) 
        AND p.Score >= 0
),
TagSummary AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1)) AS TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS UpvotedCount,
        AVG(Score) AS AverageScore
    FROM 
        RankedPosts
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
         SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    GROUP BY 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1))
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        UpvotedCount,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagSummary
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.UpvotedCount,
    tt.AverageScore,
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score
FROM 
    TopTags tt
JOIN 
    RankedPosts rp ON FIND_IN_SET(tt.TagName, rp.Tags) > 0
WHERE 
    tt.TagRank <= 5 
ORDER BY 
    tt.TagRank, rp.CreationDate DESC;
