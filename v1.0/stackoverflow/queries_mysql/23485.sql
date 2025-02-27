
WITH UserVoteStats AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
           COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
           COUNT(v.Id) AS TotalVotesCount,
           COALESCE((SELECT COUNT(DISTINCT b.Id)
                     FROM Badges b 
                     WHERE b.UserId = u.Id AND b.Class = 1), 0) AS GoldBadges,
           COALESCE((SELECT COUNT(DISTINCT b.Id)
                     FROM Badges b 
                     WHERE b.UserId = u.Id AND b.Class = 2), 0) AS SilverBadges,
           COALESCE((SELECT COUNT(DISTINCT b.Id)
                     FROM Badges b 
                     WHERE b.UserId = u.Id AND b.Class = 3), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostActivityStats AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.OwnerUserId,
           p.Score,
           COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
           COALESCE(MAX(v.CreationDate), '1900-01-01') AS LastVoteDate,
           (SELECT COUNT(*) FROM (SELECT p2.OwnerUserId, p2.CreationDate FROM Posts p2 WHERE p2.OwnerUserId = p.OwnerUserId ORDER BY p2.CreationDate DESC LIMIT 5) AS recent_posts) AS RecentPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.Score
),
FinalBenchmark AS (
    SELECT uvs.UserId,
           uvs.DisplayName,
           uvs.UpVotesCount,
           uvs.DownVotesCount,
           uvs.TotalVotesCount,
           uvs.GoldBadges,
           uvs.SilverBadges,
           uvs.BronzeBadges,
           pas.PostId,
           pas.Title AS PostTitle,
           pas.Score AS PostScore,
           pas.CommentCount,
           (CASE 
                WHEN pas.LastVoteDate < (NOW() - INTERVAL 1 YEAR) THEN 'Inactive'
                WHEN pas.RecentPostRank <= 5 THEN 'Active Top Contributor'
                ELSE 'Occasionally Active'
            END) AS UserPostActivityStatus
    FROM UserVoteStats uvs
    LEFT JOIN PostActivityStats pas ON uvs.UserId = pas.OwnerUserId
    WHERE uvs.TotalVotesCount > 0 
      AND (uvs.GoldBadges + uvs.SilverBadges + uvs.BronzeBadges) > 0
    ORDER BY uvs.UpVotesCount DESC, uvs.TotalVotesCount DESC
)
SELECT *,
       (SELECT GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') 
        FROM (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagName
              FROM (SELECT @row := @row + 1 AS n
                    FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION 
                          SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION 
                          SELECT 9 UNION SELECT 10) AS numbers, 
                    (SELECT @row := 0) r) numbers
              WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag
        LEFT JOIN Tags t ON t.TagName = tag.TagName
        WHERE t.IsModeratorOnly IS FALSE) AS RelevantTags
FROM FinalBenchmark fb
JOIN Posts p ON fb.PostId = p.Id
WHERE p.CreationDate > NOW() - INTERVAL 6 MONTH
  AND (p.Title IS NOT NULL AND p.Title != '')
  AND (fb.UserPostActivityStatus = 'Active Top Contributor' OR fb.UserPostActivityStatus = 'Occasionally Active')
ORDER BY fb.UserPostActivityStatus, fb.PostScore DESC;
