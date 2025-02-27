
WITH RelevantPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ph.CreationDate AS HistoryCreationDate,
        pt.Name AS PostTypeName
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11, 12, 13)
        JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 30 DAY) 
        AND p.ViewCount > 100
),

TagSummary AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        RelevantPosts
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
        UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5
),

OwnerActivity AS (
    SELECT 
        rp.OwnerDisplayName,
        SUM(rp.ViewCount) AS TotalViews,
        SUM(rp.Score) AS TotalScore,
        COUNT(*) AS PostCount
    FROM 
        RelevantPosts rp
    GROUP BY 
        rp.OwnerDisplayName
),

PostHistorySummary AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pht.Name) AS HistoryTypes
    FROM 
        PostHistory ph
        JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    rp.ViewCount,
    rp.Score,
    ts.Tag,
    oa.TotalViews,
    oa.TotalScore,
    oa.PostCount,
    phts.HistoryTypes
FROM 
    RelevantPosts rp
    JOIN TagSummary ts ON rp.Tags LIKE CONCAT('%', ts.Tag, '%')
    JOIN OwnerActivity oa ON rp.OwnerDisplayName = oa.OwnerDisplayName
    LEFT JOIN PostHistorySummary phts ON rp.PostId = phts.PostId
ORDER BY 
    oa.TotalViews DESC, 
    rp.Score DESC;
