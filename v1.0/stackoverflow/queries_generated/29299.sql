WITH TagStatistics AS (
    SELECT 
        TagName,
        COUNT(*) as PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(ViewCount) as AvgViews,
        AVG(Score) as AvgScore
    FROM 
        Posts
    JOIN 
        Tags ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '>')::int[])
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AvgViews,
        AvgScore,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.QuestionCount,
    tt.AnswerCount,
    tt.AvgViews,
    tt.AvgScore,
    u.DisplayName AS TopContributor,
    u.Reputation
FROM 
    TopTags tt
LEFT JOIN 
    Posts p ON p.Id IN (
        SELECT 
            PostId
        FROM 
            Votes 
        WHERE 
            VoteTypeId = 2 -- Upvotes
    )
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    tt.TagRank <= 10
ORDER BY 
    tt.PostCount DESC;
