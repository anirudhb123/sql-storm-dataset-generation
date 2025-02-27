WITH RecursiveTagCTE AS (
    SELECT Id, TagName, Count, 1 AS Level
    FROM Tags
    WHERE IsModeratorOnly = 0

    UNION ALL

    SELECT t.Id, t.TagName, t.Count, c.Level + 1
    FROM Tags t
    INNER JOIN RecursiveTagCTE c ON t.ExcerptPostId = c.Id
),
UserBadgesCTE AS (
    SELECT u.Id AS UserId, u.DisplayName, 
           COUNT(b.Id) AS BadgeCount,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStatsCTE AS (
    SELECT p.OwnerUserId,
           COUNT(p.Id) AS TotalPosts,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
           AVG(p.Score) AS AvgScore,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(p.Id) DESC) AS RN
    FROM Posts p
    GROUP BY p.OwnerUserId
)
SELECT 
    u.DisplayName AS UserName,
    COALESCE(bc.BadgeCount, 0) AS BadgeCount,
    bc.GoldBadges,
    bc.SilverBadges,
    bc.BronzeBadges,
    ps.TotalPosts,
    ps.QuestionCount,
    ps.AnswerCount,
    ps.AvgScore,
    COUNT(DISTINCT pt.Id) AS TotalTags,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
FROM Users u
LEFT JOIN UserBadgesCTE bc ON u.Id = bc.UserId
LEFT JOIN PostStatsCTE ps ON u.Id = ps.OwnerUserId
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Tags t ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
LEFT JOIN RecursiveTagCTE rtc ON t.Id = rtc.Id
WHERE (ps.TotalPosts > 5 OR bc.BadgeCount > 0)
  AND (p.CreationDate >= NOW() - INTERVAL '1 year' OR p.CreationDate IS NULL)
GROUP BY u.DisplayName, bc.BadgeCount, bc.GoldBadges, bc.SilverBadges, bc.BronzeBadges,
         ps.TotalPosts, ps.QuestionCount, ps.AnswerCount, ps.AvgScore
HAVING COUNT(DISTINCT t.Id) > 2
ORDER BY u.DisplayName;

