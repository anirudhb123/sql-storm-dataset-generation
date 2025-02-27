
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
        value AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        value
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
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
        TagStats ts ON ts.Tag = SUBSTRING(
            ru.Tags, 2, LEN(ru.Tags) - 2
        )
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
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;
