WITH TagAggregates AS (
    SELECT 
        tag.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        AVG(u.Reputation) AS AvgReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS UserNames
    FROM Tags AS tag
    LEFT JOIN Posts AS p ON p.Tags LIKE CONCAT('%', tag.TagName, '%')
    LEFT JOIN Users AS u ON p.OwnerUserId = u.Id
    GROUP BY tag.TagName
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        p.Title,
        STRING_AGG(ph.Comment, '; ') AS CloseReasons,
        COUNT(*) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM PostHistory AS ph
    JOIN Posts AS p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Considering close and reopen actions
    GROUP BY ph.PostId, p.Title
),
SelectedTags AS (
    SELECT 
        TagName 
    FROM TagAggregates 
    WHERE PostCount > 5 AND AvgReputation > 100
)
SELECT 
    ta.TagName,
    ta.PostCount,
    ta.QuestionCount,
    ta.AnswerCount,
    ta.WikiCount,
    ta.AvgReputation,
    ta.UserNames,
    cph.Title,
    cph.CloseReasons,
    cph.CloseCount,
    cph.LastClosedDate
FROM TagAggregates AS ta
LEFT JOIN ClosedPostHistory AS cph ON ta.TagName IN (SELECT TagName FROM SelectedTags)
WHERE ta.PostCount > 10 -- Filtering for tags with significant activity
ORDER BY ta.PostCount DESC, ta.AvgReputation DESC;
