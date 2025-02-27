
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(p.LastActivityDate) AS LastActivityDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentActivity AS (
    SELECT 
        UserId,
        MAX(LastActivityDate) AS LastActiveDate
    FROM 
        UserActivity
    GROUP BY 
        UserId
),
HighReputationUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.PostCount,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.CommentCount,
        ua.BadgeCount,
        ra.LastActiveDate
    FROM 
        UserActivity ua
    JOIN 
        RecentActivity ra ON ua.UserId = ra.UserId
    WHERE 
        ra.LastActiveDate > DATEADD(DAY, -30, '2024-10-01 12:34:56')
    ORDER BY 
        ua.Reputation DESC
)
SELECT 
    hru.DisplayName,
    hru.Reputation,
    hru.PostCount,
    hru.QuestionCount,
    hru.AnswerCount,
    hru.CommentCount,
    hru.BadgeCount,
    COALESCE(ROUND((CAST(hru.Reputation AS FLOAT) / NULLIF(hru.PostCount, 0)), 2), 0) AS ReputationPerPost
FROM 
    HighReputationUsers hru
WHERE 
    hru.PostCount > 0
ORDER BY 
    hru.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
