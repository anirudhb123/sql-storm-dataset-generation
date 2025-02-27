WITH TagStats AS (
    SELECT 
        tag.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.AnswerCount > 0 THEN 1 ELSE 0 END) AS QuestionsWithAnswers,
        AVG(u.Reputation) AS AverageUserReputation
    FROM Tags tag
    LEFT JOIN Posts p ON p.Tags LIKE '%' || tag.TagName ||'%'
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE tag.IsModeratorOnly = 0
    GROUP BY tag.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        PositivePosts,
        QuestionsWithAnswers,
        AverageUserReputation,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS RowNum
    FROM TagStats
),
MostActiveUsers AS (
    SELECT 
        u.DisplayName,
        COUNT(p.Id) AS PostsCount,
        COUNT(c.Id) AS CommentsCount,
        SUM(v.BountyAmount) AS TotalBountyWon
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON c.UserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.DisplayName
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.PositivePosts,
    tt.QuestionsWithAnswers,
    tt.AverageUserReputation,
    au.DisplayName AS MostActiveUser,
    au.PostsCount,
    au.CommentsCount,
    au.TotalBountyWon
FROM TopTags tt
JOIN MostActiveUsers au ON au.PostsCount = (
    SELECT MAX(PostsCount) FROM MostActiveUsers
)
WHERE tt.RowNum <= 10
ORDER BY tt.PostCount DESC;
