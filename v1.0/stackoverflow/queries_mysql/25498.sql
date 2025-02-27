
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 10 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
), 
TagStatistics AS (
    SELECT 
        p.Id AS PostId,
        TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS Tag, 
        COUNT(*) AS TagUsageCount
    FROM 
        Posts p
    JOIN (
        SELECT 
            1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) n 
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, Tag
),
TopTags AS (
    SELECT 
        Tag,
        SUM(TagUsageCount) AS TotalUsage
    FROM 
        TagStatistics
    GROUP BY 
        Tag
    ORDER BY 
        TotalUsage DESC
    LIMIT 5 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.OwnerDisplayName,
    fp.CommentCount,
    tt.Tag AS TopTag,
    tt.TotalUsage AS TagUsageCount
FROM 
    FilteredPosts fp
JOIN 
    TopTags tt ON fp.Tags LIKE CONCAT('%', tt.Tag, '%')
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC
LIMIT 100;
