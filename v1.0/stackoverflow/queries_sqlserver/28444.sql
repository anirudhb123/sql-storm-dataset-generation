
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
        AVG(p.Score) AS AvgPostScore,
        AVG(p.ViewCount) AS AvgViewCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    CROSS APPLY STRING_SPLIT(p.Tags, '><') AS tag
    LEFT JOIN 
        Tags t ON t.TagName = LTRIM(RTRIM(REPLACE(tag.value, '<', '')))
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUserPostStats AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        AcceptedAnswerCount,
        AvgPostScore,
        AvgViewCount,
        Tags,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPostStats
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    QuestionCount,
    AnswerCount,
    AcceptedAnswerCount,
    AvgPostScore,
    AvgViewCount,
    Tags
FROM 
    TopUserPostStats
WHERE 
    PostRank <= 10
ORDER BY 
    AvgPostScore DESC;
