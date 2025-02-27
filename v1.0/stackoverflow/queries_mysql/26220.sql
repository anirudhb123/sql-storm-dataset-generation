
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
         SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - 
         CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
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
        WHEN ts.QuestionCount > 0 THEN ROUND(ts.TotalViews / ts.QuestionCount, 2)
        ELSE 0
    END AS AvgViewsPerQuestion,
    CASE 
        WHEN ts.UserCount > 0 THEN ROUND(ts.TotalViews / ts.UserCount, 2)
        ELSE 0
    END AS AvgViewsPerUser
FROM 
    TagStats ts
ORDER BY 
    ts.QuestionCount DESC, ts.TotalViews DESC;
