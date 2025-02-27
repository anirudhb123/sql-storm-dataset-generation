WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        AVG(u.Reputation) AS AvgReputation,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS UsageCount
    FROM Tags t
    JOIN Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY t.TagName
    ORDER BY UsageCount DESC
    LIMIT 10
),
RecentEdits AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        P.title,
        u.DisplayName AS EditorName
    FROM PostHistory ph
    JOIN Users u ON ph.UserId = u.Id
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (4, 5) -- considering only title and body edits
    ORDER BY ph.CreationDate DESC
    LIMIT 5
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.PositiveScoreCount,
    us.AvgReputation,
    us.UserRank,
    pt.TagName,
    pt.UsageCount,
    re.PostId,
    re.CreationDate AS LastEditDate,
    re.title AS EditedPostTitle,
    re.EditorName
FROM UserStats us
CROSS JOIN PopularTags pt
LEFT JOIN RecentEdits re ON us.UserId = re.UserId
ORDER BY us.UserRank, pt.UsageCount DESC, re.LastEditDate DESC;
