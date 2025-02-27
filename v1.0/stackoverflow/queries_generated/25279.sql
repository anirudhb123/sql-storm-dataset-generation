WITH TagStats AS (
    SELECT 
        t.TagName,
        p.ViewCount,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName, p.ViewCount
),
TopTags AS (
    SELECT 
        TagName,
        ViewCount,
        PostCount,
        QuestionsCount,
        AnswersCount,
        AvgUserReputation,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStats
),
PopularTags AS (
    SELECT 
        TagName,
        ViewCount,
        PostCount,
        QuestionsCount,
        AnswersCount,
        AvgUserReputation
    FROM 
        TopTags
    WHERE 
        Rank <= 10
)
SELECT 
    pt.TagName, 
    pt.PostCount, 
    pt.QuestionsCount, 
    pt.AnswersCount,
    pt.AvgUserReputation,
    SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosureCount,
    SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount
FROM 
    PopularTags pt
LEFT JOIN 
    Posts p ON p.Tags LIKE '%' || pt.TagName || '%'
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    pt.TagName, pt.PostCount, pt.QuestionsCount, pt.AnswersCount, pt.AvgUserReputation
ORDER BY 
    pt.PostCount DESC;
