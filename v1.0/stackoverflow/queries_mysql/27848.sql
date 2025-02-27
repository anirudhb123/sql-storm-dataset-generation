
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS Author,
        (
            SELECT COUNT(*)
            FROM Comments c
            WHERE c.PostId = p.Id
        ) AS CommentCount,
        (
            SELECT COUNT(*)
            FROM PostHistory ph
            WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 11)
        ) AS CloseReopenCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
),
TagFrequency AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS Frequency
    FROM 
        Posts
    JOIN 
        (SELECT @row := @row + 1 AS n FROM (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) t, (SELECT @row := 0) r) n
    WHERE 
        PostTypeId = 1 AND Tags IS NOT NULL
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS TagRank
    FROM 
        TagFrequency
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Author,
    rp.CommentCount,
    rp.CloseReopenCount,
    tt.Tag,
    tt.Frequency AS TagFrequency
FROM 
    RankedPosts rp
LEFT JOIN 
    TopTags tt ON rp.UserPostRank = 1
WHERE 
    tt.TagRank <= 5  
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC;
