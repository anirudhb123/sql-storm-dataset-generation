WITH TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.Id, t.TagName
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS RevisionCount,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS Comments,
        STRING_AGG(DISTINCT ph.UserDisplayName) AS Editors
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Only tracking title, body, and tags edits
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
FinalResults AS (
    SELECT 
        ts.TagId,
        ts.TagName,
        ts.PostCount,
        ts.TotalViews,
        ts.TotalScore,
        ts.AvgUserReputation,
        ph.RevisionCount,
        ph.Comments,
        ph.Editors
    FROM 
        TagStats ts
    LEFT JOIN 
        PostHistoryInfo ph ON ts.TagId = (SELECT unnest(string_to_array(p.Tags, '<>'))::int FROM Posts p WHERE p.Tags IS NOT NULL LIMIT 1) -- just an example link
)
SELECT 
    TagId,
    TagName,
    PostCount,
    TotalViews,
    TotalScore,
    AvgUserReputation,
    COALESCE(RevisionCount, 0) AS RevisionCount,
    COALESCE(Comments, 'No comments') AS Comments,
    COALESCE(Editors, 'No editors') AS Editors
FROM 
    FinalResults
ORDER BY 
    TotalViews DESC, PostCount DESC;
