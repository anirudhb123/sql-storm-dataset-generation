
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 
),

TagDetails AS (
    SELECT 
        p.Id AS PostId,
        TRIM(BOTH '>' FROM Tag) AS Tag
    FROM Posts p
    CROSS JOIN (
        SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
        FROM (SELECT @rownum := @rownum + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) AS numbers, (SELECT @rownum := 0) AS r) AS numbers
        WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) AS Tag
    WHERE p.Tags IS NOT NULL
),

TagStats AS (
    SELECT 
        td.Tag,
        COUNT(*) AS TagCount,
        AVG(rp.Score) AS AvgScore,
        SUM(rp.ViewCount) AS TotalViews
    FROM TagDetails td
    JOIN RankedPosts rp ON td.PostId = rp.PostId
    GROUP BY td.Tag
),

TopTags AS (
    SELECT 
        ts.Tag,
        RANK() OVER (ORDER BY ts.TagCount DESC) AS TagRank
    FROM TagStats ts
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.ViewCount,
    rp.Score,
    rp.OwnerDisplayName,
    rp.Reputation,
    tt.Tag,
    ts.TagCount,
    ts.AvgScore,
    ts.TotalViews
FROM RankedPosts rp
JOIN TopTags tt ON tt.Tag IN (
    SELECT TRIM(BOTH '>' FROM Tag) 
    FROM (
        SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', numbers.n), '><', -1) AS Tag
        FROM (SELECT @rownum := @rownum + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) AS numbers, (SELECT @rownum := 0) AS r) AS numbers
        WHERE CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, '><', '')) >= numbers.n - 1
    ) AS Tag
)
JOIN TagStats ts ON tt.Tag = ts.Tag
WHERE rp.RankByScore = 1 AND tt.TagRank <= 5 
ORDER BY ts.TagCount DESC, rp.Score DESC;
