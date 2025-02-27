WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        ARRAY_AGG(DISTINCT TRIM(UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '> <')))) FILTER (WHERE TRIM(UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '> <'))) <> '') ) AS TagsArray
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1 -- Filters only Questions
    GROUP BY 
        p.Id
),
TagCount AS (
    SELECT 
        t.Id AS TagId, 
        t.TagName, 
        COUNT(pt.PostId) AS PostsCount
    FROM 
        Tags t
    LEFT JOIN 
        ProcessedTags pt ON pt.TagsArray && ARRAY[t.TagName] -- Checking if tag matches with post's tags
    GROUP BY 
        t.Id, t.TagName
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS QuestionsAnswered
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 2 -- Filters only Answers
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        QuestionsAnswered DESC
    LIMIT 5
),
TopTags AS (
    SELECT 
        TagId,
        TagName,
        PostsCount,
        ROW_NUMBER() OVER (ORDER BY PostsCount DESC) AS Rnk
    FROM 
        TagCount
    WHERE 
        PostsCount > 0
)
SELECT 
    mu.DisplayName AS TopUser,
    tt.TagName AS MostCommonTag,
    tt.PostsCount AS NumberOfPostsWithTag
FROM 
    MostActiveUsers mu
JOIN 
    TopTags tt ON tt.Rnk = 1 -- Most common tag with the highest count
ORDER BY 
    mu.QuestionsAnswered DESC;
