
WITH UserBadges AS (
    SELECT UserId, COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
TopUsers AS (
    SELECT Id, Reputation, DisplayName, CreationDate, LastAccessDate, Views, UpVotes, DownVotes
    FROM Users
    WHERE Reputation >= 1000
    ORDER BY Reputation DESC
    LIMIT 10
),
PostStats AS (
    SELECT OwnerUserId, COUNT(*) AS TotalPosts, 
           SUM(CASE WHEN PostTypeId = 2 THEN 1 END) AS TotalAnswers,
           SUM(CASE WHEN PostTypeId = 1 THEN 1 END) AS TotalQuestions,
           SUM(ViewCount) AS TotalViews
    FROM Posts
    GROUP BY OwnerUserId
),
UserPostStats AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation, u.CreationDate, 
           p.TotalPosts, p.TotalAnswers, p.TotalQuestions, p.TotalViews,
           b.GoldBadges, b.SilverBadges, b.BronzeBadges
    FROM TopUsers u
    JOIN PostStats p ON u.Id = p.OwnerUserId
    LEFT JOIN UserBadges b ON u.Id = b.UserId
)
SELECT ups.UserId, ups.DisplayName, ups.Reputation, ups.CreationDate, 
       ups.TotalPosts, ups.TotalAnswers, ups.TotalQuestions, ups.TotalViews,
       ups.GoldBadges, ups.SilverBadges, ups.BronzeBadges,
       LISTAGG(t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS PopularTags
FROM UserPostStats ups
LEFT JOIN Tags t 
ON EXISTS (SELECT 1 FROM Posts ps WHERE ps.Tags LIKE CONCAT('%<', t.TagName, '>%') AND ps.OwnerUserId = ups.UserId)
GROUP BY ups.UserId, ups.DisplayName, ups.Reputation, ups.CreationDate, 
         ups.TotalPosts, ups.TotalAnswers, ups.TotalQuestions, ups.TotalViews,
         ups.GoldBadges, ups.SilverBadges, ups.BronzeBadges
ORDER BY ups.Reputation DESC, ups.TotalPosts DESC;
