WITH UserActivity AS (
    SELECT u.Id AS UserId, u.DisplayName, 
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
           SUM(CASE WHEN p.PostTypeId = 10 THEN 1 ELSE 0 END) AS PostsClosed,
           COUNT(DISTINCT p.Id) AS TotalPosts,
           AVG(COALESCE(DATEDIFF(second, p.CreationDate, p.LastActivityDate), 0)) AS AvgPostLifeSpan
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 100
    GROUP BY u.Id
),
TopTags AS (
    SELECT t.TagName, COUNT(pt.Id) AS PostCount
    FROM Tags t
    JOIN Posts pt ON t.Id = ANY(string_to_array(pt.Tags, '><')::int[])
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    LIMIT 10
),
UserBadges AS (
    SELECT u.Id AS UserId, 
           COUNT(b.Id) AS BadgeCount, 
           STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT ua.DisplayName, ua.QuestionsAsked, ua.AnswersGiven, ua.PostsClosed, ua.TotalPosts, 
       ua.AvgPostLifeSpan, tb.TagName, ub.BadgeCount, ub.BadgeNames
FROM UserActivity ua
JOIN TopTags tb ON tb.PostCount > 5
JOIN UserBadges ub ON ua.UserId = ub.UserId
ORDER BY ua.TotalPosts DESC, ub.BadgeCount DESC;
