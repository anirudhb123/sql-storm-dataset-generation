-- Performance Benchmarking Query for StackOverflow Schema

WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        MAX(u.CreationDate) AS AccountCreationDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostsAssociated,
        SUM(p.ViewCount) AS TotalViewCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%' -- Simplistic tag match
    GROUP BY 
        t.Id, t.TagName
),
VoteStats AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalScore,
    ups.TotalViews,
    COUNT(t.TagId) AS AssociatedTags,
    COALESCE(vs.TotalVotes, 0) AS UserTotalVotes,
    COALESCE(vs.UpVotes, 0) AS UserUpVotes,
    COALESCE(vs.DownVotes, 0) AS UserDownVotes,
    ups.AccountCreationDate
FROM 
    UserPostStats ups
LEFT JOIN 
    TagStats t ON t.PostsAssociated > 0
LEFT JOIN 
    VoteStats vs ON ups.UserId = vs.UserId
GROUP BY 
    ups.UserId, ups.DisplayName, ups.TotalPosts, ups.TotalQuestions, ups.TotalAnswers,
    ups.TotalScore, ups.TotalViews, ups.AccountCreationDate
ORDER BY 
    ups.TotalScore DESC, ups.TotalPosts DESC;
