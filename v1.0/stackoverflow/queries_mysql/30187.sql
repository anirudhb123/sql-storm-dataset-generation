
WITH RECURSIVE PopularQuestions AS (
    SELECT 
        p.Id AS QuestionId, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        p.OwnerUserId, 
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
        AND p.AcceptedAnswerId IS NOT NULL  
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(IFNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(IFNULL(p.AnswerCount, 0)) AS TotalAnswers,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
),
RecentActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(c.Id) AS TotalComments,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY 
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    q.Title,
    q.Score,
    u.DisplayName,
    IFNULL(us.BadgeCount, 0) AS BadgeCount,
    IFNULL(us.TotalViews, 0) AS TotalViews,
    IFNULL(us.TotalAnswers, 0) AS TotalAnswers,
    IFNULL(ra.TotalComments, 0) AS TotalComments,
    IFNULL(ra.TotalVotes, 0) AS TotalVotes,
    CASE 
        WHEN us.AverageScore > 10 THEN 'High Engager'
        WHEN us.AverageScore BETWEEN 5 AND 10 THEN 'Moderate Engager'
        ELSE 'Low Engager'
    END AS EngagementLevel
FROM 
    PopularQuestions q
JOIN 
    Users u ON q.OwnerUserId = u.Id
LEFT JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    RecentActivity ra ON u.Id = ra.OwnerUserId
WHERE 
    q.Rank <= 10
ORDER BY 
    q.Score DESC;
