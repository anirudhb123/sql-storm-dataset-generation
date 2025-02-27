-- Performance Benchmarking Query

-- This query gets various aggregated statistics on posts including counts of questions, answers, likes, and average scores,
-- while also examining user contributions through user reputation and badge counts.
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
    SUM(v.VoteTypeId = 2) AS TotalUpVotes, -- Upvotes
    SUM(v.VoteTypeId = 3) AS TotalDownVotes, -- Downvotes
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    COUNT(DISTINCT CASE WHEN bh.UserId IS NOT NULL THEN bh.Id END) AS TotalPostHistories
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistory bh ON p.Id = bh.PostId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalPosts DESC;
