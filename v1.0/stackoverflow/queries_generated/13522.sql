-- Benchmarking SQL Query to analyze user contributions and post interactions
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS PostCount,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
    SUM(coalesce(p.ViewCount, 0)) AS TotalViews,
    SUM(coalesce(c.Score, 0)) AS TotalCommentScore,
    SUM(coalesce(v.BountyAmount, 0)) AS TotalBountySpent,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    COUNT(DISTINCT ph.Id) AS PostHistoryCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    PostCount DESC, TotalViews DESC;
