WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName AS Owner, 
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= DATEADD(month, -12, GETDATE()) 
    AND p.ViewCount > 100
), ScoreStats AS (
    SELECT PostTypeId, AVG(Score) AS AvgScore, MAX(Score) AS MaxScore, MIN(Score) AS MinScore, COUNT(*) AS PostCount
    FROM Posts
    WHERE CreationDate >= DATEADD(month, -12, GETDATE())
    GROUP BY PostTypeId
), UserBadges AS (
    SELECT u.Id AS UserId, b.Class, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, b.Class
)
SELECT rp.Title, rp.Owner, rp.Score, rp.ViewCount, sb.AvgScore, sb.MaxScore, sb.MinScore, ub.BadgeCount
FROM RankedPosts rp
JOIN ScoreStats sb ON rp.PostTypeId = sb.PostTypeId
LEFT JOIN UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE rp.Rank <= 5
ORDER BY rp.PostTypeId, rp.Score DESC;
