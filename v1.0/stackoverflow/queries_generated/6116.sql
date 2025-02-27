WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
), PopularTags AS (
    SELECT Tags.TagName, COUNT(Posts.Id) AS PostCount
    FROM Tags
    LEFT JOIN Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, ',')::int[])
    GROUP BY Tags.TagName
    HAVING COUNT(Posts.Id) > 10
), UserActivity AS (
    SELECT Users.DisplayName, COUNT(Posts.Id) AS PostCount, SUM(Comments.Score) AS TotalCommentScore
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN Comments ON Posts.Id = Comments.PostId
    WHERE Users.Reputation > 1000
    GROUP BY Users.DisplayName
), RecentPostHistory AS (
    SELECT PostHistory.PostId, MAX(PostHistory.CreationDate) AS LastEditDate
    FROM PostHistory
    GROUP BY PostHistory.PostId
)

SELECT 
    U.DisplayName,
    UB.BadgeCount,
    UP.TagName,
    UAct.PostCount,
    UAct.TotalCommentScore,
    RPH.LastEditDate
FROM 
    UserBadges UB
JOIN 
    Users U ON U.Id = UB.UserId
JOIN 
    UserActivity UAct ON UAct.DisplayName = U.DisplayName
JOIN 
    PopularTags UP ON UP.PostCount > 5
JOIN 
    RecentPostHistory RPH ON RPH.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.Id)
WHERE 
    U.CreationDate >= NOW() - INTERVAL '1 year'
ORDER BY 
    UB.BadgeCount DESC, 
    UAct.PostCount DESC;
