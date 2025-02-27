WITH RECURSIVE UserBadges AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COUNT(b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT p.OwnerUserId,
           COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS AnswerCount,
           COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
           SUM(p.Score) AS TotalScore,
           AVG(COALESCE(p.ViewCount, 0)) AS AvgViews,
           SUM(COALESCE(p.FavoriteCount, 0)) AS TotalFavorites
    FROM Posts p
    GROUP BY p.OwnerUserId
),
RecentPostHistory AS (
    SELECT ph.UserId, 
           ph.PostId, 
           ph.CreationDate, 
           p.Title,
           p.Body,
           ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.CreationDate > NOW() - INTERVAL '1 year'
)
SELECT u.Id AS UserId,
       u.DisplayName,
       ub.TotalBadges,
       COALESCE(ps.AnswerCount, 0) AS AnswerCount,
       COALESCE(ps.QuestionCount, 0) AS QuestionCount,
       COALESCE(ps.TotalScore, 0) AS TotalScore,
       COALESCE(ps.AvgViews, 0) AS AvgViews,
       COALESCE(ps.TotalFavorites, 0) AS TotalFavorites,
       MAX(rph.CreationDate) AS LastActivityDate,
       STRING_AGG(DISTINCT rph.Title, '; ') AS RelatedPostTitles
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN RecentPostHistory rph ON u.Id = rph.UserId AND rph.rn = 1
WHERE u.Reputation > 1000
GROUP BY u.Id, u.DisplayName, ub.TotalBadges
ORDER BY u.Reputation DESC;
