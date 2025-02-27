WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        AVG(p.ViewCount) AS AverageViews,
        ARRAY_AGG(DISTINCT u.DisplayName) AS TopUsers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        t.Count > 0
    GROUP BY 
        t.TagName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(ph.PostHistoryTypeId) AS LastEditType
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
MergedStats AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.PositivePosts,
        ts.AverageViews,
        ts.TopUsers,
        phs.EditCount,
        phs.LastEditDate,
        CASE 
            WHEN phs.LastEditType IS NULL THEN 'No Edits'
            WHEN phs.LastEditType IN (4, 5) THEN 'Title or Body Edited'
            ELSE 'Other Edits'
        END AS EditType
    FROM 
        TagStatistics ts
    LEFT JOIN 
        PostHistoryStats phs ON ts.PostCount > 0
)
SELECT 
    TagName,
    PostCount,
    PositivePosts,
    AverageViews,
    TopUsers,
    EditCount,
    LastEditDate,
    EditType
FROM 
    MergedStats
ORDER BY 
    PostCount DESC,
    PositivePosts DESC
LIMIT 10;
