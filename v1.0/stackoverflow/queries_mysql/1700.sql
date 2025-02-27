
WITH UserBadgeCounts AS (
    SELECT UserId, 
           COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
           COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
           COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostAnalytics AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.OwnerUserId,
           p.ViewCount,
           COALESCE(v.UpVotes, 0) AS UpVotes,
           COALESCE(v.DownVotes, 0) AS DownVotes,
           COALESCE(c.CommentCount, 0) AS CommentCount,
           u.DisplayName,
           @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
           @prev_owner_user_id := p.OwnerUserId
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, 
               SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    JOIN Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS vars
    WHERE p.CreationDate > NOW() - INTERVAL 1 YEAR
),
TopUsers AS (
    SELECT u.Id, 
           u.DisplayName, 
           ub.GoldBadges, 
           ub.SilverBadges, 
           ub.BronzeBadges, 
           SUM(pa.ViewCount) AS TotalViews,
           @rank := @rank + 1 AS Rank
    FROM Users u
    LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
    LEFT JOIN PostAnalytics pa ON u.Id = pa.OwnerUserId
    CROSS JOIN (SELECT @rank := 0) AS r
    GROUP BY u.Id, u.DisplayName, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
)
SELECT t.DisplayName,
       t.Rank,
       t.TotalViews,
       t.GoldBadges,
       t.SilverBadges,
       t.BronzeBadges
FROM TopUsers t
WHERE t.Rank <= 10
ORDER BY t.TotalViews DESC;
