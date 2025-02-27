WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        AVG(u.Reputation) AS AvgReputation,
        MAX(u.CreationDate) AS MaxCreationDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        SUM(CASE WHEN p.AnswerCount > 0 THEN 1 ELSE 0 END) AS AnsweredCount,
        AVG(p.ViewCount) AS AvgViewCount,
        MAX(p.LastActivityDate) AS LatestActivity
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        ub.UserId,
        ub.BadgeCount,
        ub.AvgReputation,
        ub.MaxCreationDate,
        ps.PostCount,
        ps.PositiveScoreCount,
        ps.AnsweredCount,
        ps.AvgViewCount,
        ps.LatestActivity
    FROM 
        UserBadgeCounts ub
    LEFT JOIN 
        PostStats ps ON ub.UserId = ps.OwnerUserId
)
SELECT 
    u.DisplayName,
    cs.BadgeCount,
    cs.AvgReputation,
    cs.MaxCreationDate,
    cs.PostCount,
    cs.PositiveScoreCount,
    cs.AnsweredCount,
    cs.AvgViewCount,
    COALESCE(cs.LatestActivity, 'No Activity') AS LatestActivity
FROM 
    CombinedStats cs
JOIN 
    Users u ON cs.UserId = u.Id
WHERE 
    cs.BadgeCount > 0
ORDER BY 
    cs.AvgReputation DESC, cs.PostCount DESC
LIMIT 10;
