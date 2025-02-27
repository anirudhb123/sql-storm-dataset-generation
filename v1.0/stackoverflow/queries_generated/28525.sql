WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS AverageScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS ActiveUsers
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY (string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
RecentPostEdits AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
),
LastEditDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        re.UserDisplayName AS LastEditor,
        re.CreationDate AS LastEditDate,
        re.Comment AS EditComment,
        re.Text AS EditText
    FROM 
        Posts p
    LEFT JOIN 
        RecentPostEdits re ON p.Id = re.PostId
    WHERE 
        re.EditRank = 1
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.AverageScore,
    ts.ActiveUsers,
    le.PostId,
    le.Title,
    le.PostCreationDate,
    le.LastEditor,
    le.LastEditDate,
    le.EditComment,
    le.EditText
FROM 
    TagStatistics ts
LEFT JOIN 
    LastEditDetails le ON ts.PostCount > 0
ORDER BY 
    ts.TotalViews DESC, ts.TagName;
