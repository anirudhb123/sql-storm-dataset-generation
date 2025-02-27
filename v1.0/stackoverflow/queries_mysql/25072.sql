
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY LENGTH(TRIM(LEADING '<' FROM TRIM(TRAILING '>' FROM p.Tags))) - LENGTH(REPLACE(TRIM(LEADING '<' FROM TRIM(TRAILING '>' FROM p.Tags)), '><', '')) + 1 ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 MONTH
),

TagStats AS (
    SELECT 
        tag,
        COUNT(*) AS PostCount,
        AVG(Score) AS AvgScore
    FROM (
        SELECT 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS tag,
            Score
        FROM 
            Posts
        JOIN 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
        WHERE 
            PostTypeId = 1
    ) AS TagsData
    GROUP BY 
        tag
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    ts.tag,
    ts.PostCount,
    ts.AvgScore,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount
FROM 
    RankedPosts rp
JOIN 
    TagStats ts ON ts.tag IN (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', numbers.n), '><', -1)) FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers WHERE CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, '><', '')) >= numbers.n - 1)
WHERE 
    rp.Rank <= 5
ORDER BY 
    ts.AvgScore DESC, 
    rp.Score DESC;
