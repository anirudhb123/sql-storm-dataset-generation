
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '> <', n.n), '> <', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
         SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n ON 
        CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '> <', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        Tag
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
    LIMIT 10
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
            DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '> <', n.n), '> <', -1) AS Tag,
            OwnerUserId
         FROM 
            Posts
         JOIN 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL 
             SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n ON 
            CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '> <', '')) >= n.n - 1
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
