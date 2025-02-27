WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
), 
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart votes
    GROUP BY 
        u.Id
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.QuestionCount,
    u.TotalViews,
    u.TotalBounties,
    COALESCE(tp.PostCount, 0) AS TotalTags,
    COALESCE(tp.TotalViews, 0) AS TotalTagViews
FROM 
    UserStatistics u
LEFT JOIN 
    (SELECT 
         t.TagName,
         COUNT(DISTINCT p.Id) AS PostCount,
         SUM(p.ViewCount) AS TotalViews
     FROM 
         Tags t
     JOIN 
         Posts p ON p.Tags LIKE '%' || t.TagName || '%'
     GROUP BY 
         t.TagName) tp ON tp.TagName IN (SELECT DISTINCT Tags FROM Posts WHERE OwnerUserId = u.UserId)
WHERE 
    u.QuestionCount > 0 
ORDER BY 
    u.TotalViews DESC
LIMIT 10;

-- Performance Benchmarking by comparing recent activity of users with the most viewed posts.
WITH RecentActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS RecentPostCount,
        SUM(p.ViewCount) AS RecentTotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        u.Id
)
SELECT 
    r.UserId,
    r.DisplayName,
    r.RecentPostCount,
    r.RecentTotalViews,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = r.UserId AND b.Class = 1) AS GoldBadges,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = r.UserId AND b.Class = 2) AS SilverBadges,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = r.UserId AND b.Class = 3) AS BronzeBadges
FROM 
    RecentActivity r
ORDER BY 
    r.RecentTotalViews DESC
LIMIT 5;

-- Recursive CTE to generate a hierarchy of user activity based on accepted answers.
WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        1 AS Level,
        COUNT(a.Id) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts q ON u.Id = q.OwnerUserId AND q.PostTypeId = 1
    LEFT JOIN 
        Posts a ON q.AcceptedAnswerId = a.Id
    GROUP BY 
        u.Id
    
    UNION ALL

    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Level + 1,
        ua.AcceptedAnswers + COUNT(a.Id)
    FROM 
        UserActivity ua
    JOIN 
        Posts q ON ua.UserId = q.OwnerUserId AND q.PostTypeId = 1
    LEFT JOIN 
        Posts a ON q.AcceptedAnswerId = a.Id
    GROUP BY 
        ua.UserId, ua.DisplayName, ua.Level
)
SELECT 
    UserId,
    DisplayName,
    MAX(AcceptedAnswers) AS TotalAcceptedAnswers
FROM 
    UserActivity
GROUP BY 
    UserId, DisplayName
ORDER BY 
    TotalAcceptedAnswers DESC
LIMIT 10;
