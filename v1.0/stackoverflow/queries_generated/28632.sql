WITH TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(Users.Reputation) AS AvgUserReputation,
        STRING_AGG(DISTINCT Users.DisplayName, ', ') AS ActiveUsers
    FROM
        Tags
    JOIN Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, ',')::int[])
    LEFT JOIN Users ON Posts.OwnerUserId = Users.Id
    GROUP BY Tags.TagName
),
CloseReasonCounts AS (
    SELECT 
        TRIM(REPLACE(PostHistory.Comment, 'Close Reason: ', '')) AS CloseReason,
        COUNT(PostHistory.Id) AS CloseReasonCount
    FROM 
        PostHistory
    JOIN PostHistoryTypes ON PostHistory.PostHistoryTypeId = PostHistoryTypes.Id
    WHERE 
        PostHistoryTypes.Name = 'Post Closed'
    GROUP BY CloseReason
),
UserBadges AS (
    SELECT 
        Users.DisplayName,
        COUNT(Badges.Id) AS BadgeCount,
        STRING_AGG(DISTINCT Badges.Name, ', ') AS BadgeNames 
    FROM 
        Users
    LEFT JOIN Badges ON Users.Id = Badges.UserId
    GROUP BY Users.DisplayName
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AvgUserReputation,
    ts.ActiveUsers,
    COUNT(DISTINCT ub.DisplayName) AS UniqueBadgeHolders,
    STRING_AGG(DISTINCT ub.BadgeNames, '; ') AS AllBadges,
    r.CloseReason,
    r.CloseReasonCount
FROM 
    TagStatistics ts
LEFT JOIN UserBadges ub ON ts.ActiveUsers LIKE '%' || ub.DisplayName || '%'
LEFT JOIN CloseReasonCounts r ON ts.TagName = (SELECT Tags.TagName FROM Tags WHERE Tags.ExcerptPostId IS NOT NULL LIMIT 1)
GROUP BY 
    ts.TagName, r.CloseReason, r.CloseReasonCount
ORDER BY 
    ts.PostCount DESC, ts.TagName;
