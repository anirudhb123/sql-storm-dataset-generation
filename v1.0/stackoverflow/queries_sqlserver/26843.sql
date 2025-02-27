
WITH TagCounts AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '> <') 
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        value
),
MostActiveUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS QuestionCount,
        SUM(ViewCount) AS TotalViews,
        SUM(AnswerCount) AS TotalAnswers
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        OwnerUserId
    ORDER BY 
        QuestionCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
TagDetails AS (
    SELECT 
        ta.Tag,
        tc.PostCount,
        mu.OwnerUserId,
        mu.QuestionCount,
        mu.TotalViews,
        mu.TotalAnswers
    FROM 
        TagCounts tc
    JOIN 
        (SELECT 
            DISTINCT value AS Tag,
            OwnerUserId
         FROM 
            Posts
         WHERE 
            PostTypeId = 1) ta ON ta.Tag = tc.Tag
    JOIN 
        MostActiveUsers mu ON ta.OwnerUserId = mu.OwnerUserId
)
SELECT 
    td.Tag,
    td.PostCount,
    m.DisplayName,
    m.Reputation,
    td.QuestionCount,
    td.TotalViews,
    td.TotalAnswers
FROM 
    TagDetails td
JOIN 
    Users m ON td.OwnerUserId = m.Id
ORDER BY 
    td.PostCount DESC, td.TotalViews DESC;
