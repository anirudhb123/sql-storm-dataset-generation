WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AverageScore,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN STRING_TO_ARRAY(p.Tags, ',') AS tags_array ON TRUE
    LEFT JOIN Tags t ON t.TagName = TRIM(BOTH ' ' FROM tags_array)
    GROUP BY p.OwnerUserId
),
UserMetrics AS (
    SELECT 
        ub.DisplayName,
        ub.BadgeCount,
        ub.BadgeNames,
        ps.PostCount,
        ps.QuestionCount,
        ps.AnswerCount,
        ps.AverageScore,
        COALESCE(ps.Tags, 'No Tags') AS Tags
    FROM UserBadgeCounts ub
    LEFT JOIN PostStatistics ps ON ub.UserId = ps.OwnerUserId
)
SELECT 
    DisplayName,
    BadgeCount,
    BadgeNames,
    PostCount,
    QuestionCount,
    AnswerCount,
    AverageScore,
    Tags
FROM UserMetrics
ORDER BY BadgeCount DESC, AverageScore DESC
LIMIT 10;
