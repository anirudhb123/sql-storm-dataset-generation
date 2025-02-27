
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        AVG(p.ViewCount) AS AverageViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.PostCount,
        us.QuestionCount,
        us.AnswerCount,
        us.Upvotes,
        us.Downvotes,
        us.AverageViews,
        @row_num := @row_num + 1 AS Rank
    FROM 
        UserStatistics us, (SELECT @row_num := 0) r
    WHERE 
        us.PostCount >= 10
),
TopUsers AS (
    SELECT
        au.UserId,
        au.DisplayName,
        au.PostCount,
        au.QuestionCount,
        au.AnswerCount,
        au.Upvotes,
        au.Downvotes,
        au.AverageViews
    FROM 
        ActiveUsers au
    WHERE 
        au.Rank <= 10
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.PostCount AS TotalPosts,
    tu.QuestionCount AS TotalQuestions,
    tu.AnswerCount AS TotalAnswers,
    tu.Upvotes AS TotalUpvotes,
    tu.Downvotes AS TotalDownvotes,
    tu.AverageViews AS AvgPostViews,
    GROUP_CONCAT(DISTINCT p.Title SEPARATOR ', ') AS PostTitles,
    GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS AssociatedTags
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN 
    (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', n.n), ',', -1)) AS tag
     FROM posts p
     JOIN (SELECT a.N FROM 
           (SELECT 1 AS N UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
           UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) 
           AS a) n ON CHAR_LENGTH(p.Tags)
           -CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= n.n - 1) AS tag_list ON TRUE
LEFT JOIN 
    Tags t ON tag_list.tag = t.TagName
GROUP BY 
    tu.UserId, tu.DisplayName, tu.PostCount, tu.QuestionCount, tu.AnswerCount, tu.Upvotes, tu.Downvotes, tu.AverageViews
ORDER BY 
    tu.Upvotes DESC;
