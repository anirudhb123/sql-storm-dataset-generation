
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        u.Reputation AS UserReputation,
        u.DisplayName AS UserDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
),
TopTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1) AS TagName,
        COUNT(*) AS TagUsage
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= n.n - 1
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
    GROUP BY 
        TagName
    ORDER BY 
        TagUsage DESC
    LIMIT 10
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT c.UserDisplayName ORDER BY c.UserDisplayName SEPARATOR ', ') AS CommentAuthors
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.Body,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    r.TagCount,
    r.UserReputation,
    r.UserDisplayName,
    pc.CommentCount,
    pc.CommentAuthors,
    tt.TagName AS PopularTag,
    tt.TagUsage AS TagUsageCount
FROM 
    RankedPosts r
LEFT JOIN 
    PostComments pc ON r.PostId = pc.PostId
LEFT JOIN 
    TopTags tt ON FIND_IN_SET(tt.TagName, SUBSTRING_INDEX(SUBSTRING_INDEX(r.Tags, '>', n.n), '>', -1))
WHERE 
    r.PostRank = 1 
ORDER BY 
    r.Score DESC, r.ViewCount DESC;
