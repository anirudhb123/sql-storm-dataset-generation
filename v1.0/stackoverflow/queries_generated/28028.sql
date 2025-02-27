WITH TagCounts AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Tags t
    LEFT JOIN Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY t.TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount, 
        QuestionCount, 
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM TagCounts
),
UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(v.VoteTypeId = 2, 0)::int) AS TotalUpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)::int) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
Benchmark AS (
    SELECT 
        tt.TagName,
        SoBN.UserId,
        SoBN.DisplayName,
        SoBN.PostsCreated,
        SoBN.TotalViews,
        SoBN.TotalUpVotes,
        SoBN.TotalDownVotes,
        tt.PostCount AS AssociatedPostCount,
        tt.QuestionCount AS AssociatedQuestionCount,
        tt.AnswerCount AS AssociatedAnswerCount
    FROM TopTags tt
    JOIN UserStats SoBN ON tt.QuestionCount > 0
    WHERE tt.TagRank <= 10
)
SELECT 
    TagName,
    UserId,
    DisplayName,
    PostsCreated,
    TotalViews,
    TotalUpVotes,
    TotalDownVotes,
    AssociatedPostCount,
    AssociatedQuestionCount,
    AssociatedAnswerCount
FROM Benchmark
ORDER BY TotalViews DESC, PostsCreated DESC;
