
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        value AS Tag
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '> <') 
    WHERE 
        p.PostTypeId = 1  
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TagStats AS (
    SELECT 
        pt.Tag,
        COUNT(DISTINCT pt.PostId) AS QuestionCount,
        COUNT(DISTINCT u.Id) AS UserCount,
        SUM(ua.TotalViews) AS TotalViews
    FROM 
        PostTags pt
    JOIN 
        Users u ON u.Id IN (SELECT OwnerUserId FROM Posts WHERE Id = pt.PostId)
    JOIN 
        UserActivity ua ON ua.UserId = u.Id
    GROUP BY 
        pt.Tag
)
SELECT 
    ts.Tag,
    ts.QuestionCount,
    ts.UserCount,
    ts.TotalViews,
    CASE 
        WHEN ts.QuestionCount > 0 THEN ROUND(CAST(ts.TotalViews AS decimal(10, 2)) / CAST(ts.QuestionCount AS decimal(10, 2)), 2)
        ELSE 0
    END AS AvgViewsPerQuestion,
    CASE 
        WHEN ts.UserCount > 0 THEN ROUND(CAST(ts.TotalViews AS decimal(10, 2)) / CAST(ts.UserCount AS decimal(10, 2)), 2)
        ELSE 0
    END AS AvgViewsPerUser
FROM 
    TagStats ts
ORDER BY 
    ts.QuestionCount DESC, ts.TotalViews DESC;
