
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Owner,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
),
TagStats AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS JOIN (
        SELECT 
            a.N + b.N * 10 AS n
        FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
    ) n
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        Tag
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(*) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        QuestionCount DESC
    LIMIT 10
),
CombinedStats AS (
    SELECT 
        ru.Owner,
        ru.PostId,
        ru.Title,
        ru.CreationDate,
        ru.Score AS QuestionScore,
        ts.PostCount AS TagCount,
        tu.QuestionCount AS UserQuestionCount,
        tu.TotalViews,
        tu.TotalScore
    FROM 
        RankedPosts ru
    LEFT JOIN 
        TagStats ts ON ts.Tag = SUBSTRING_INDEX(SUBSTRING_INDEX(ru.Tags, '><', n.n), '><', -1)
    LEFT JOIN 
        TopUsers tu ON ru.Owner = tu.DisplayName
)
SELECT 
    Owner,
    COUNT(PostId) AS TotalPosts,
    AVG(QuestionScore) AS AverageScore,
    COUNT(DISTINCT TagCount) AS TotalUniqueTags,
    SUM(UserQuestionCount) AS TotalQuestionsByUser,
    SUM(TotalViews) AS TotalViewsByUser,
    AVG(TotalScore) AS AverageUserScore
FROM 
    CombinedStats
GROUP BY 
    Owner
ORDER BY 
    TotalPosts DESC
LIMIT 5;
