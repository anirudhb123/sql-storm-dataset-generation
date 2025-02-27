
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0 
),

TagStats AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT a.N + 1 n FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                                    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                                    (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                                    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1))
)

SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    r.OwnerDisplayName,
    r.Tags,
    ts.TagName,
    ts.PostCount
FROM 
    RankedPosts r
JOIN 
    TagStats ts ON ts.TagName IN (TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(r.Tags, '><', n.n), '><', -1)))
JOIN 
    (SELECT a.N + 1 n FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                                UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                                UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
    ON CHAR_LENGTH(r.Tags) - CHAR_LENGTH(REPLACE(r.Tags, '><', '')) >= n.n - 1
WHERE 
    r.Rank = 1 
ORDER BY 
    r.Score DESC, r.ViewCount DESC
LIMIT 100;
