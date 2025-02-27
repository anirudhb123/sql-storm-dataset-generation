WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(u.Reputation) AS AvgUserReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS UsersContributed
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    GROUP BY t.TagName
),
CloseReasonStats AS (
    SELECT 
        cht.Name AS CloseReason,
        COUNT(ph.Id) AS CloseCount,
        STRING_AGG(DISTINCT p.Title, ', ') AS ClosedPosts
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    JOIN CloseReasonTypes cht ON CAST(ph.Comment AS INTEGER) = cht.Id
    JOIN Posts p ON ph.PostId = p.Id
    WHERE pht.Name = 'Post Closed'
    GROUP BY cht.Name
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AvgUserReputation,
    ts.UsersContributed,
    crs.CloseReason,
    crs.CloseCount,
    crs.ClosedPosts,
    ub.UserId,
    ub.DisplayName AS BadgeOwner,
    ub.BadgeCount,
    ub.BadgeNames
FROM TagStats ts
FULL OUTER JOIN CloseReasonStats crs ON ts.TagName IS NOT NULL OR crs.CloseReason IS NOT NULL
FULL OUTER JOIN UserBadges ub ON ub.BadgeCount > 0
ORDER BY ts.PostCount DESC, crs.CloseCount DESC, ub.BadgeCount DESC;

