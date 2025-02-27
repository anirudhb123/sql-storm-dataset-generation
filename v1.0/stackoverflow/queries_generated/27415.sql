WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount ELSE 0 END) AS TotalAcceptedAnswers,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS ViralPostsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopContributors AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.QuestionsCount,
        ua.AnswersCount,
        ua.TotalAcceptedAnswers,
        ua.ViralPostsCount,
        ROW_NUMBER() OVER (ORDER BY ua.TotalPosts DESC) AS Rank
    FROM 
        UserActivity ua
    WHERE 
        ua.TotalPosts > 0
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostsCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, '><')::int[])
    GROUP BY 
        t.TagName
    ORDER BY 
        PostsCount DESC
    LIMIT 10
)
SELECT 
    tc.Rank,
    tc.DisplayName,
    tc.TotalPosts,
    tc.QuestionsCount,
    tc.AnswersCount,
    tc.TotalAcceptedAnswers,
    tc.ViralPostsCount,
    pt.TagName,
    pt.PostsCount
FROM 
    TopContributors tc
JOIN 
    PopularTags pt ON pt.PostsCount > 5
ORDER BY 
    tc.Rank;
