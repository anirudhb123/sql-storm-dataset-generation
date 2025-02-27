WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        AnswerCount,
        QuestionCount,
        AvgUserReputation,
        DENSE_RANK() OVER (ORDER BY AnswerCount DESC) AS PopularityRank
    FROM 
        TagStats
)
SELECT 
    pt.TagName,
    pt.PostCount,
    pt.QuestionCount,
    pt.AnswerCount,
    pt.AvgUserReputation,
    ph.CreationDate AS LastEditDate,
    u.DisplayName AS LastEditor,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS ClosureCount,
    SUM(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 ELSE 0 END) AS EditSuggestionsCount
FROM 
    PopularTags pt
LEFT JOIN 
    Posts p ON p.Tags LIKE '%' || pt.TagName || '%'
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Users u ON ph.UserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    pt.PopularityRank <= 10
GROUP BY 
    pt.TagName, pt.PostCount, pt.QuestionCount, pt.AnswerCount, pt.AvgUserReputation, ph.CreationDate, u.DisplayName
ORDER BY 
    pt.PopularityRank;
