
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR) 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5 
),
TagsExploded AS (
    SELECT 
        tp.PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(tp.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        TopPosts tp
    JOIN (
        SELECT 
            a.N + b.N * 10 + 1 n
        FROM 
            (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
        ORDER BY n
    ) numbers ON CHAR_LENGTH(tp.Tags) - CHAR_LENGTH(REPLACE(tp.Tags, '><', '')) >= numbers.n - 1
),
TagCount AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount
    FROM 
        TagsExploded
    GROUP BY 
        Tag
)
SELECT 
    t.Tag,
    t.PostCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId IN (SELECT PostId FROM TopPosts)) AS TotalComments
FROM 
    TagCount t
LEFT JOIN 
    Posts p ON p.Tags LIKE CONCAT('%', t.Tag, '%')
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
GROUP BY 
    t.Tag, t.PostCount
ORDER BY 
    t.PostCount DESC;
