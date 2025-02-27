WITH RankedTags AS (
    SELECT 
        TRIM(t.TagName) AS Tag,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
        AVG(u.Reputation) AS AverageReputation,
        ROW_NUMBER() OVER (PARTITION BY TRIM(t.TagName) ORDER BY COUNT(DISTINCT p.Id) DESC) AS rn
    FROM 
        Tags t
    JOIN 
        Posts p ON POSITION(CONCAT('<', t.TagName, '>') IN p.Tags) > 0
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        t.IsModeratorOnly = 0 
    GROUP BY 
        TRIM(t.TagName)
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        AcceptedAnswerCount,
        AverageReputation
    FROM 
        RankedTags
    WHERE 
        rn = 1
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
DetailedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        t.Tag AS TagName
    FROM 
        Posts p
    JOIN 
        TopTags tt ON POSITION(CONCAT('<', tt.Tag, '>') IN p.Tags) > 0
    JOIN 
        Tags t ON tt.Tag = t.TagName
)
SELECT 
    d.TagName,
    COUNT(d.PostId) AS TotalPosts,
    SUM(d.Score) AS TotalScore,
    AVG(d.ViewCount) AS AverageViews,
    SUM(d.AnswerCount) AS TotalAcceptedAnswers
FROM 
    DetailedPosts d
GROUP BY 
    d.TagName
ORDER BY 
    TotalPosts DESC;
