WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS WikiCount,
        AVG(u.Reputation) AS AverageUserReputation,
        COUNT(DISTINCT u.Id) AS UniqueUsers,
        MAX(COALESCE(p.ViewCount, 0)) AS MaxViews,
        MAX(COALESCE(p.Score, 0)) AS MaxScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS EditCount,
        ARRAY_AGG(DISTINCT pht.Name) AS EditTypes,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.WikiCount,
    ts.AverageUserReputation,
    ts.UniqueUsers,
    ts.MaxViews,
    ts.MaxScore,
    phs.EditCount,
    phs.EditTypes,
    phs.LastEditDate
FROM 
    TagStatistics ts
LEFT JOIN 
    PostHistorySummary phs ON ts.PostCount > 0 AND phs.PostId IN (SELECT p.Id FROM Posts p WHERE t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[]))
WHERE 
    ts.PostCount > 0
ORDER BY 
    ts.PostCount DESC, 
    ts.AverageUserReputation DESC;
