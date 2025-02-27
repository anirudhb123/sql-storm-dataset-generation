
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.Body IS NOT NULL
),
TagCount AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS Count
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        Count
    FROM 
        TagCount
    ORDER BY 
        Count DESC
    LIMIT 10
),
PostHistoryDismissed AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pht.Name ORDER BY pht.Name SEPARATOR ', ') AS DismissedHistory
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        pht.Name IN ('Post Deleted', 'Post Closed', 'Post Undeleted')
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.Author,
    rp.CreationDate,
    rp.Score,
    th.DismissedHistory,
    tt.Tag AS TopTag
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDismissed th ON rp.PostId = th.PostId
JOIN 
    TopTags tt ON rp.Tags LIKE CONCAT('%', tt.Tag, '%')
WHERE 
    rp.rn = 1  
ORDER BY 
    rp.CreationDate DESC;
