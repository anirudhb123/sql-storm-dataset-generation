-- Performance Benchmarking Query

-- This query retrieves the number of posts, questions, answers, and comments created by each user, 
-- as well as the total votes they received on their posts over the last year.

SELECT 
    u.Id AS UserID,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS TotalAnswers,
    COUNT(c.Id) AS TotalComments,
    COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpVotes,
    COALESCE(SUM(v.VoteTypeId = 3), 0) AS TotalDownVotes
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC;
