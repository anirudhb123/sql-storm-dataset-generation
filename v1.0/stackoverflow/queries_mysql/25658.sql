
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS PostRank,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR) 
),
TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 + 1 n FROM 
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b) n
        ON n.n <= CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) + 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
PopularTags AS (
    SELECT 
        Tag,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS PopularityRank
    FROM 
        TagCounts
    WHERE 
        TagCount > 10 
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        GROUP_CONCAT(DISTINCT pht.Name ORDER BY pht.Name SEPARATOR ', ') AS ActionTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.Reputation,
    pt.Tag AS PopularTag,
    pha.HistoryCount,
    pha.ActionTypes
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON pt.Tag = SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', n.n), '><', -1)
LEFT JOIN 
    PostHistoryAnalysis pha ON pha.PostId = rp.PostId
WHERE 
    rp.PostRank = 1 
ORDER BY 
    rp.ViewCount DESC, 
    rp.Reputation DESC
LIMIT 50;
