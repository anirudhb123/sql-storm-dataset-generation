WITH TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(Users.Reputation) AS AvgReputation
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    WHERE 
        Tags.Count > 0
    GROUP BY 
        Tags.TagName
),
PostHistoryStats AS (
    SELECT 
        PostId,
        COUNT(*) AS EditCount,
        MAX(CreationDate) AS LastEditDate,
        JSON_AGG(DISTINCT PostHistoryTypeId ORDER BY PostHistoryTypeId) AS HistoryTypes
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId IN (4, 5, 6) -- Edits related to titles and bodies
    GROUP BY 
        PostId
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AvgReputation,
    phs.EditCount,
    phs.LastEditDate,
    phs.HistoryTypes
FROM 
    TagStatistics ts
LEFT JOIN 
    PostHistoryStats phs ON phs.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%>' || ts.TagName || '<%')
ORDER BY 
    ts.PostCount DESC, ts.AvgReputation DESC;
