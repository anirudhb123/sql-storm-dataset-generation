WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsPosted,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersPosted,
        SUM(p.ViewCount) AS TotalViews,
        SUM(v.VoteTypeId IN (2, 3)) AS TotalVotes,
        AVG(DATEDIFF(second, u.CreationDate, getdate())) / 86400.0 AS AverageAccountAgeInDays
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        TotalPosts,
        QuestionsPosted,
        AnswersPosted,
        TotalViews,
        TotalVotes,
        AverageAccountAgeInDays,
        RANK() OVER (ORDER BY TotalVotes DESC) AS ActivityRank
    FROM 
        UserActivity
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.QuestionsPosted,
    u.AnswersPosted,
    u.TotalViews,
    u.TotalVotes,
    u.AverageAccountAgeInDays
FROM 
    TopActiveUsers u
WHERE 
    u.ActivityRank <= 10
ORDER BY 
    u.TotalVotes DESC;
