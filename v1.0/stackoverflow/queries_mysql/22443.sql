
WITH PostStats AS (
    SELECT p.Id AS PostId,
           p.OwnerUserId,
           COUNT(DISTINCT c.Id) AS CommentCount,
           COUNT(DISTINCT v.Id) AS VoteCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
           MAX(ph.CreationDate) AS LastHistoryDate,
           GROUP_CONCAT(DISTINCT t.TagName) AS TagsList
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName
               FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
                     UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
               WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS t ON TRUE
    WHERE p.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY p.Id, p.OwnerUserId
),
UserStats AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COALESCE(MAX(ps.CommentCount), 0) AS TotalComments,
           COALESCE(SUM(ps.UpVoteCount), 0) AS TotalUpVotes,
           COALESCE(SUM(ps.DownVoteCount), 0) AS TotalDownVotes,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 50
    GROUP BY u.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT ps.PostId,
           ps.OwnerUserId,
           ps.LastHistoryDate,
           ps.TagsList,
           @row_number := IF(@prev_owner = ps.OwnerUserId, @row_number + 1, 1) AS RankByComments,
           @prev_owner := ps.OwnerUserId
    FROM PostStats ps
    CROSS JOIN (SELECT @row_number := 0, @prev_owner := NULL) AS vars
    WHERE ps.VoteCount > 10
    ORDER BY ps.OwnerUserId, ps.CommentCount DESC
),
UserRanked AS (
    SELECT us.UserId,
           us.DisplayName,
           us.TotalComments,
           us.TotalUpVotes,
           us.TotalDownVotes,
           @user_rank := @user_rank + 1 AS UserRank
    FROM UserStats us
    CROSS JOIN (SELECT @user_rank := 0) AS vars
    ORDER BY us.TotalComments DESC
)
SELECT ur.UserId,
       ur.DisplayName,
       ur.TotalComments,
       ur.TotalUpVotes,
       ur.TotalDownVotes,
       fp.PostId,
       fp.TagsList,
       fp.LastHistoryDate
FROM UserRanked ur
LEFT JOIN FilteredPosts fp ON ur.UserId = fp.OwnerUserId
WHERE (ur.TotalComments > 0 OR ur.TotalUpVotes > 0)
  AND (fp.RankByComments <= 5 OR fp.LastHistoryDate IS NULL)
ORDER BY ur.UserRank, fp.LastHistoryDate DESC;
