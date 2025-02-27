WITH TagCounts AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    GROUP BY 
        TagName
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
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
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
    MostActiveUsers mau ON mau.QuestionCount > 0 -- Only those users who asked questions
WHERE 
    tt.TagRank <= 10  -- Top 10 tags
ORDER BY 
    tt.PostCount DESC, 
    mau.PostCount DESC;
