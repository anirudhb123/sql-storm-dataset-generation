
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY ARRAY_SIZE(SPLIT(SUBSTR(p.Tags, 2, LEN(p.Tags) - 2), '><')) ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CURRENT_TIMESTAMP() - INTERVAL '1 month'
),

TagStats AS (
    SELECT 
        tag,
        COUNT(*) AS PostCount,
        AVG(score) AS AvgScore
    FROM (
        SELECT 
            TRIM(value) AS tag,
            Score
        FROM 
            Posts,
            LATERAL FLATTEN(input => SPLIT(SUBSTR(Tags, 2, LEN(Tags) - 2), '><')) AS value
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
    TagStats ts ON ts.tag = ANY(SPLIT(SUBSTR(rp.Tags, 2, LEN(rp.Tags) - 2), '><'))
WHERE 
    rp.Rank <= 5
ORDER BY 
    ts.AvgScore DESC, 
    rp.Score DESC;
