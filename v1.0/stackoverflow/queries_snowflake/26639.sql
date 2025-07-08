
WITH TagCounts AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts,
        LATERAL SPLIT_TO_TABLE(SUBSTR(Tags, 2, LENGTH(Tags) - 2), '><') AS t
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TRIM(value)
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(IFF(p.PostTypeId = 1, 1, 0)) AS QuestionCount,
        SUM(IFF(p.PostTypeId = 2, 1, 0)) AS AnswerCount,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tt.TagName,
    tt.PostCount,
    mau.DisplayName,
    mau.PostCount AS TotalPosts,
    mau.QuestionCount,
    mau.AnswerCount
FROM 
    TopTags tt
JOIN 
    MostActiveUsers mau ON mau.QuestionCount > 0 
WHERE 
    tt.TagRank <= 10  
ORDER BY 
    tt.PostCount DESC, 
    mau.PostCount DESC;
