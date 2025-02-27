
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgReputation,
        STRING_AGG(DISTINCT CASE WHEN u.Id IS NOT NULL THEN u.DisplayName END, ', ') AS ActiveUsers
    FROM 
        Tags AS t
    LEFT JOIN 
        Posts AS p ON p.Tags LIKE '%' + t.TagName + '%'
    LEFT JOIN 
        Users AS u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        QuestionCount,
        AnswerCount,
        AvgReputation,
        ActiveUsers
    FROM 
        TagStats
    WHERE 
        PostCount > 0
    ORDER BY 
        PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.QuestionCount,
    tt.AnswerCount,
    tt.AvgReputation,
    tt.ActiveUsers,
    PH.EditCount,
    PH.LastEditDate,
    PT.Name AS PostTypeName
FROM 
    TopTags AS tt
LEFT JOIN (
    SELECT 
        p.Tags,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts AS p
    JOIN 
        PostHistory AS ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        p.Tags
) AS PH ON tt.TagName IN (SELECT value FROM STRING_SPLIT(PH.Tags, ', '))
JOIN 
    PostTypes AS PT ON pt.Id = (SELECT TOP 1 p.PostTypeId FROM Posts AS p WHERE p.Tags LIKE '%' + tt.TagName + '%')
ORDER BY 
    tt.PostCount DESC;
