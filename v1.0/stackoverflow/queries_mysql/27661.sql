
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagsArray
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag
         FROM Posts p CROSS JOIN (
             SELECT a.N + 1 AS n
             FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
                   SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
                   SELECT 8 UNION ALL SELECT 9) a
             ORDER BY n
         ) n
         WHERE n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.ViewCount, p.Score
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag
         FROM Posts p CROSS JOIN (
             SELECT a.N + 1 AS n
             FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
                   SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
                   SELECT 8 UNION ALL SELECT 9) a
             ORDER BY n
         ) n
         WHERE n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5 
),
PostHistoryReports AS (
    SELECT 
        ph.PostId,
        p.Title,
        ph.CreationDate,
        p.OwnerUserId,
        PHType.Name AS ChangeType,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes PHType ON ph.PostHistoryTypeId = PHType.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL 1 MONTH 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.Score,
    rp.TagsArray,
    COALESCE(pt.TagCount, 0) AS PopularTagCount,
    phr.UserDisplayName AS LastEditedBy,
    phr.ChangeType,
    phr.Comment AS ChangeComment,
    phr.CreationDate AS ChangeDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON FIND_IN_SET(pt.TagName, rp.TagsArray) > 0 
LEFT JOIN 
    PostHistoryReports phr ON rp.PostId = phr.PostId
WHERE 
    rp.PostRank <= 3 
ORDER BY 
    rp.OwnerDisplayName, 
    rp.Score DESC;
