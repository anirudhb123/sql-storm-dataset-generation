
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
        p.CreationDate >= CAST(DATEADD(day, -30, '2024-10-01') AS DATE) 
        AND p.ViewCount > 100
),

TagSummary AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS PostCount
    FROM 
        RelevantPosts
        CROSS APPLY STRING_SPLIT(Tags, '><')
    GROUP BY 
        value
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
        STRING_AGG(DISTINCT pht.Name, ',') AS HistoryTypes
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
    JOIN TagSummary ts ON rp.Tags LIKE '%' + ts.Tag + '%'
    JOIN OwnerActivity oa ON rp.OwnerDisplayName = oa.OwnerDisplayName
    LEFT JOIN PostHistorySummary phts ON rp.PostId = phts.PostId
ORDER BY 
    oa.TotalViews DESC, 
    rp.Score DESC;
