-- Performance Benchmarking Query
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AvgScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.CommentCount) AS TotalComments
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
        COUNT(p.Id) AS PostsWithTag,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.Id, t.TagName
),
VoteStats AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.AvgScore,
    ups.TotalViews,
    ups.TotalComments,
    ts.TagId,
    ts.TagName,
    ts.PostsWithTag,
    ts.TotalViews AS TagTotalViews,
    vs.TotalVotes,
    vs.TotalUpVotes,
    vs.TotalDownVotes
FROM 
    UserPostStats ups
LEFT JOIN 
    TagStats ts ON ts.PostsWithTag > 0
LEFT JOIN 
    VoteStats vs ON vs.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ups.UserId)
ORDER BY 
    ups.TotalPosts DESC, ups.AvgScore DESC;
