-- Performance Benchmarking Query

-- This query intends to retrieve and benchmark the performance of various operations on the Stack Overflow schema
-- by joining different tables and aggregating results to assess the efficiency.

WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),

BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b 
    GROUP BY 
        b.UserId
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.AvgViewCount,
    ups.AvgScore,
    bs.TotalBadges,
    bs.GoldBadges,
    bs.SilverBadges,
    bs.BronzeBadges
FROM 
    UserPostStats ups
LEFT JOIN 
    BadgeStats bs ON ups.UserId = bs.UserId
ORDER BY 
    ups.TotalPosts DESC
LIMIT 100; -- Limiting results for better performance analysis
