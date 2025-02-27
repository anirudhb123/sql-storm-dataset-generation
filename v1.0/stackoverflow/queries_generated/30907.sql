WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= '2023-01-01'
        AND p.PostTypeId = 1 -- Only questions
),
TopTags AS (
    SELECT 
        SUBSTRING(p.Tags FROM 2 FOR CHAR_LENGTH(p.Tags) - 2) AS TagList,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        TagList
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        pt.Name AS PostHistoryType,
        ph.Comment,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 DAY'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Reputation,
    rp.OwnerDisplayName,
    tt.TagList,
    ph.PostHistoryType,
    ph.CreationDate AS HistoryDate,
    ph.Comment
FROM 
    RankedPosts rp
LEFT JOIN 
    TopTags tt ON tt.TagList LIKE '%' || rp.TagList || '%' 
LEFT JOIN 
    RecentPostHistory ph ON ph.PostId = rp.PostId AND ph.HistoryRank = 1
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;

-- Additional metrics for performance benchmarking
SELECT 
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    COUNT(DISTINCT rp.OwnerDisplayName) AS UniqueUsers,
    SUM(rp.Score) AS TotalScore,
    AVG(rp.ViewCount) AS AvgViewCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentPostHistory ph ON ph.PostId = rp.PostId
WHERE 
    ph.PostHistoryTypeId IN (10, 11, 12, 13) -- Closed, Reopened, Deleted, Undeleted
    AND ph.CreationDate >= now() - INTERVAL '7 DAY'
HAVING 
    COUNT(DISTINCT ph.PostId) > 0;
