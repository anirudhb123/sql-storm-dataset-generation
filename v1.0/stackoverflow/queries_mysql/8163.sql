
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS Author,
        p.OwnerUserId
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 AND p.Score > 0
),
MostActiveUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews
    FROM Posts
    WHERE PostTypeId = 1
    GROUP BY OwnerUserId
    HAVING COUNT(*) > 10
),
TopTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM Posts
    CROSS JOIN (
        SELECT 
            a.N + b.N * 10 AS n
        FROM 
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b
    ) n
    WHERE n.n < CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) + 1
    AND PostTypeId = 1
    GROUP BY TagName
    ORDER BY TagCount DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.CreationDate,
    rp.Author,
    mau.PostCount,
    mau.TotalViews,
    tt.TagName
FROM RankedPosts rp
JOIN MostActiveUsers mau ON rp.OwnerUserId = mau.OwnerUserId
CROSS JOIN TopTags tt
WHERE rp.Rank <= 3
ORDER BY rp.ViewCount DESC, rp.Score DESC;
