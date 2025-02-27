WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
TagActivity AS (
    SELECT 
        th.TagName,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastActivityDate,
        COUNT(DISTINCT ph.UserId) AS UniqueEditors
    FROM 
        TagStats th
    JOIN 
        PostHistory ph ON th.TagName = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) 
    GROUP BY 
        th.TagName
),
PostLinksCount AS (
    SELECT 
        pl.LinkTypeId,
        COUNT(pl.Id) AS LinkCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.LinkTypeId
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ta.HistoryCount,
    ta.LastActivityDate,
    ta.UniqueEditors,
    plc.LinkCount,
    ts.AvgReputation
FROM 
    TagStats ts
LEFT JOIN 
    TagActivity ta ON ts.TagName = ta.TagName
LEFT JOIN 
    PostLinksCount plc ON ts.TagName = ANY(SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) FROM Posts p WHERE p.Tags IS NOT NULL)
WHERE 
    ts.PostCount > 10
ORDER BY 
    ts.PostCount DESC, ts.AvgReputation DESC;
