
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
), 
TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 + 1 n FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
            SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
            SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
            SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
            SELECT 8 UNION ALL SELECT 9) b) n
        WHERE 
            n.n <= CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) + 1
        GROUP BY
            TagName
    ) AS tag_names ON FIND_IN_SET(TagName, Tags)
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
), 
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        TagCount > 5 
), 
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    tt.TagName,
    rp.OwnerDisplayName,
    rp.Reputation,
    ph.UserDisplayName AS Editor,
    ph.Comment AS EditComment,
    ph.HistoryDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistories ph ON rp.PostId = ph.PostId AND ph.HistoryRank = 1  
JOIN 
    (SELECT * FROM TopTags LIMIT 10) tt ON rp.Tags LIKE CONCAT('%', tt.TagName, '%')  
WHERE 
    rp.PostRank = 1  
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
