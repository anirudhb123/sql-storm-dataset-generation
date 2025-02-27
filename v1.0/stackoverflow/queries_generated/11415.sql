-- Performance Benchmarking Query

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AveragePostScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
), 
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostsWithTagCount,
        AVG(p.ViewCount) AS AverageViewCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
    GROUP BY 
        t.TagName
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.AveragePostScore,
    us.QuestionsCount,
    us.AnswersCount,
    us.UpVotes,
    us.DownVotes,
    ts.TagName,
    ts.PostsWithTagCount,
    ts.AverageViewCount
FROM 
    UserStats us
JOIN 
    TagStats ts ON us.UserId = (SELECT OwnerUserId FROM Posts p WHERE p.Tags LIKE '%' || ts.TagName || '%')
ORDER BY 
    us.TotalPosts DESC, 
    us.AveragePostScore DESC;
