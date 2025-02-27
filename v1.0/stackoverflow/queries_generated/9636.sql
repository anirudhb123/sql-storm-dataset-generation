WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        AVG(u.Reputation) AS AvgReputation,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ph.UserId,
        ph.Comment,
        ph.CreationDate AS HistoryDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND ph.PostHistoryTypeId IN (24, 10, 12) 
),
DailyActivity AS (
    SELECT 
        DATE(creationDate) AS ActivityDate,
        COUNT(DISTINCT UserId) AS ActiveUsers,
        COUNT(*) AS TotalActivities
    FROM 
        PostEngagement
    GROUP BY 
        DATE(creationDate
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.CommentCount,
    ua.AvgReputation,
    ua.LastVoteDate,
    da.ActivityDate,
    da.ActiveUsers,
    da.TotalActivities
FROM 
    UserActivity ua
JOIN 
    DailyActivity da ON da.ActivityDate >= DATE(ua.LastVoteDate) - INTERVAL '1 month'
ORDER BY 
    ua.AvgReputation DESC,
    da.TotalActivities DESC
LIMIT 100;
