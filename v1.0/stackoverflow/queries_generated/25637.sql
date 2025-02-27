WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (10, 11, 12) THEN 1 ELSE 0 END) AS CloseVoteCount
    FROM Tags t
    JOIN Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    GROUP BY t.TagName
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS ContributionCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewsPerPost,
        AVG(p.Score) AS AvgScorePerPost
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerDisplayName,
        ph.CreationDate,
        ph.Comment,
        pt.Name AS PostHistoryType
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE ph.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
)
SELECT 
    ts.TagName,
    us.DisplayName AS Contributor,
    us.ContributionCount,
    us.TotalViews,
    us.TotalScore,
    us.AvgViewsPerPost,
    us.AvgScorePerPost,
    COUNT(rp.PostId) AS RecentPostChanges,
    STRING_AGG(DISTINCT CONCAT(rp.Title, ' (', rp.PostHistoryType, ' on ', rp.CreationDate, ')'), '; ') AS RecentChanges
FROM TagStats ts
JOIN UserStats us ON ts.PostCount > 0
LEFT JOIN RecentActivity rp ON us.ContributionCount > 0
GROUP BY ts.TagName, us.DisplayName
ORDER BY ts.PostCount DESC, us.TotalViews DESC;
