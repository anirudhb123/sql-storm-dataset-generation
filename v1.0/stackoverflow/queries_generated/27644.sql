WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(u.Reputation) AS AvgUserReputation
    FROM Tags t
    LEFT JOIN Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    GROUP BY t.TagName
),
HistoricalChanges AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
),
PopularTags AS (
    SELECT 
        ts.TagName,
        ts.QuestionCount,
        ts.AnswerCount,
        ts.TotalViews,
        ts.AvgUserReputation,
        hc.EditCount,
        hc.LastEdited,
        hc.HistoryTypes
    FROM TagStatistics ts
    JOIN HistoricalChanges hc ON ts.TagName IN (
        SELECT unnest(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><'))::varchar[])
        FROM Posts
        WHERE Posts.Id = hc.PostId
    )
    WHERE ts.PostCount > 5
    ORDER BY ts.TotalViews DESC
)
SELECT 
    pt.TagName,
    pt.QuestionCount,
    pt.AnswerCount,
    pt.TotalViews,
    pt.AvgUserReputation,
    COALESCE(pt.EditCount, 0) AS EditCount,
    COALESCE(pt.LastEdited, 'No Edits') AS LastEdited,
    COALESCE(pt.HistoryTypes, 'No History') AS HistoryTypes
FROM PopularTags pt
LIMIT 10;
