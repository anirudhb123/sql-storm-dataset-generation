-- Performance Benchmarking Query for Stack Overflow Schema

-- This query retrieves user statistics, post details, and vote counts to analyze performance
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(v.VoteTypeId = 2) AS UpVotesCount,
        SUM(v.VoteTypeId = 3) AS DownVotesCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TagPostStats AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.Reputation,
    ups.PostCount AS TotalPosts,
    ups.QuestionsCount,
    ups.AnswersCount,
    ups.UpVotesCount,
    ups.DownVotesCount,
    ups.TotalScore,
    tps.TagName,
    tps.PostCount AS TagPostCount,
    tps.TotalScore AS TagScore
FROM 
    UserPostStats ups
LEFT JOIN 
    TagPostStats tps ON ups.PostCount > 0
ORDER BY 
    ups.Reputation DESC, ups.TotalScore DESC, ups.PostCount DESC;
