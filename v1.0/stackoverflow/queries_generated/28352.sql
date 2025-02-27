WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS WikiCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
)

SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.WikiCount,
    ts.PositiveScoreCount,
    ua.DisplayName AS ActiveUser,
    ua.VoteCount,
    ua.CommentCount,
    ua.BadgeCount,
    ua.GoldBadgeCount,
    ua.SilverBadgeCount,
    ua.BronzeBadgeCount,
    rph.UserDisplayName AS RecentEditor,
    COUNT(rph.PostId) AS RecentEditCount
FROM 
    TagStatistics ts
LEFT JOIN 
    UserActivity ua ON ua.VoteCount > 0
LEFT JOIN 
    RecentPostHistory rph ON rph.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' || ts.TagName || '%')
GROUP BY 
    ts.TagName, ua.DisplayName, rph.UserDisplayName
ORDER BY 
    ts.PostCount DESC, ua.VoteCount DESC;
