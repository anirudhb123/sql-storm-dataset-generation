WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS RelatedPostCount,
        SUM(pt.ViewCount) AS TotalTagViews
    FROM Tags t
    LEFT JOIN Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
)
SELECT 
    u.DisplayName,
    u.Reputation,
    us.BadgeCount,
    ps.PostCount,
    ps.QuestionCount,
    ps.AnswerCount,
    ps.TotalViews,
    ps.AverageScore,
    t.TagName,
    ts.RelatedPostCount,
    ts.TotalTagViews
FROM UserStats us
JOIN PostStats ps ON us.UserId = ps.OwnerUserId
JOIN TagStats ts ON ts.TotalTagViews > 1000  -- Focus on tags that generate significant attention
JOIN Users u ON u.Id = us.UserId
ORDER BY us.BadgeCount DESC, ps.PostCount DESC, ts.TotalTagViews DESC
LIMIT 50;
