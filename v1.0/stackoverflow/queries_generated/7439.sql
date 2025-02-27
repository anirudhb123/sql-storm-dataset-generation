WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.UpVotes > p.DownVotes THEN 1 ELSE 0 END) AS PositivePosts,
        AVG(COALESCE(CAST(ROUND(AVG(CAST(p.Score AS float)), 2) AS float), 0)) AS AvgScore,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.PositivePosts,
    us.AvgScore,
    us.BadgeCount,
    RANK() OVER (ORDER BY us.Reputation DESC) AS ReputationRank
FROM 
    UserStats us
WHERE 
    us.PostCount > 0
ORDER BY 
    us.Reputation DESC, us.PositivePosts DESC
LIMIT 50;
