
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.Tags,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
),
TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        RankedPosts
    INNER JOIN 
        (SELECT 1 as n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
         UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        Tags IS NOT NULL
),
PopularTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        TagStatistics
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    GROUP_CONCAT(DISTINCT pt.Tag ORDER BY pt.Tag) AS PopularTags
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON FIND_IN_SET(pt.Tag, REPLACE(rp.Tags, '><', ',')) > 0
WHERE 
    rp.PostRank = 1
GROUP BY 
    rp.PostId, rp.Title, rp.Body, rp.OwnerDisplayName, rp.CreationDate, rp.Score, rp.ViewCount
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
