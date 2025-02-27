WITH TagCount AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE 
            WHEN p.PostTypeId = 1 THEN 1 
            ELSE 0 
        END) AS QuestionCount,
        SUM(CASE 
            WHEN p.PostTypeId = 2 THEN 1 
            ELSE 0 
        END) AS AnswerCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName
),
TagTopUsers AS (
    SELECT 
        t.TagName,
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY SUM(v.VoteTypeId = 2) DESC) AS UserRank
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        Votes v ON v.PostId = p.Id
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        t.TagName, u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        TagId,
        TagName, 
        PostCount,
        QuestionCount,
        AnswerCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCount
),
MostContributedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        SUM(QuestionCount) AS TotalQuestions,
        SUM(AnswerCount) AS TotalAnswers,
        COUNT(DISTINCT t.TagName) AS UniqueTags
    FROM 
        TagTopUsers ttu
    GROUP BY 
        UserId, DisplayName
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.QuestionCount,
    tt.AnswerCount,
    mu.DisplayName AS TopContributor,
    mu.TotalQuestions,
    mu.TotalAnswers,
    mu.UniqueTags
FROM 
    TopTags tt
LEFT JOIN 
    MostContributedUsers mu ON mu.UniqueTags = tt.Rank
WHERE 
    tt.Rank <= 10; -- Top 10 tags by the number of posts
