WITH TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AverageUserReputation
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%' ) -- Assuming tags are stored in <tag> format
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    GROUP BY
        t.TagName
),

CloseReasonsVisualization AS (
    SELECT
        chr.Name AS CloseReason,
        COUNT(p.Id) AS ClosedPostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS ClosedQuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS ClosedAnswerCount
    FROM
        PostHistory ph
    JOIN
        CloseReasonTypes chr ON ph.Comment::int = chr.Id -- Assuming JSON value interpretation 
    JOIN
        Posts p ON ph.PostId = p.Id
    WHERE
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY
        chr.Name
),

UserBadgeSummary AS (
    SELECT
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.DisplayName
)

SELECT
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AverageUserReputation,
    cr.CloseReason,
    cr.ClosedPostCount,
    cr.ClosedQuestionCount,
    cr.ClosedAnswerCount,
    ubd.DisplayName,
    ubd.BadgeCount,
    ubd.GoldBadges,
    ubd.SilverBadges,
    ubd.BronzeBadges
FROM
    TagStatistics ts
LEFT JOIN
    CloseReasonsVisualization cr ON ts.TagName LIKE '%' || cr.CloseReason || '%'
LEFT JOIN
    UserBadgeSummary ubd ON ubd.BadgeCount > 0
ORDER BY
    ts.PostCount DESC, cr.ClosedPostCount DESC, ubd.BadgeCount DESC;
