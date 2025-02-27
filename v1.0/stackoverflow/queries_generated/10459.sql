-- Performance benchmarking of the Stack Overflow schema

-- Measure the number of posts per user and average score of their posts
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC;

-- Measure the distribution of post types
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Measure post engagement (view count, comment count) over time
SELECT 
    DATE_TRUNC('month', p.CreationDate) AS Month,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.CommentCount) AS TotalComments
FROM 
    Posts p
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    Month
ORDER BY 
    Month;

-- Measure the number of badges awarded by user and badge class
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    GoldBadges DESC, SilverBadges DESC, BronzeBadges DESC;

-- Measure average time of post editing
SELECT 
    AVG(EXTRACT(EPOCH FROM (ph.CreationDate - p.CreationDate))) AS AverageEditTimeInSeconds
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
WHERE 
    ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
AND 
    ph.CreationDate > p.CreationDate

