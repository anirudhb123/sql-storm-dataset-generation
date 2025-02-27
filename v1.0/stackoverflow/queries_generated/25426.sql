WITH TagData AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        STRING_AGG(DISTINCT p.Title, ', ') AS SampleTitles,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(u.UpVotes) AS TotalUpvotes,
        SUM(u.DownVotes) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS EditSuggestionCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    t.TagName,
    td.PostCount,
    td.TotalViews,
    td.SampleTitles,
    us.DisplayName,
    us.QuestionsAsked,
    us.AnswersGiven,
    us.TotalUpvotes,
    us.TotalDownvotes,
    ph.CloseReopenCount,
    ph.DeleteUndeleteCount,
    ph.EditSuggestionCount
FROM 
    TagData td
JOIN 
    Posts p ON td.TagName = ANY(string_to_array(p.Tags, ','))
JOIN 
    UserStats us ON p.OwnerUserId = us.UserId
LEFT JOIN 
    PostHistoryStats ph ON p.Id = ph.PostId
WHERE 
    td.PostCount > 10
ORDER BY 
    td.TotalViews DESC, 
    us.TotalUpvotes DESC;
