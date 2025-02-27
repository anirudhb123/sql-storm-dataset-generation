
WITH UserBadgeCount AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS TotalComments,
        COALESCE(uc.BadgeCount, 0) AS UserBadgeCount
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN UserBadgeCount uc ON p.OwnerUserId = uc.UserId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.TotalComments,
    ps.UserBadgeCount,
    CASE 
        WHEN ps.UserBadgeCount > 5 THEN 'Highly Recognized'
        WHEN ps.UserBadgeCount BETWEEN 1 AND 5 THEN 'Moderately Recognized'
        ELSE 'New User'
    END AS UserRecognition,
    (SELECT COUNT(*) FROM PostStatistics ps2 WHERE ps2.Score > ps.Score) + 1 AS ScoreRank
FROM PostStatistics ps
WHERE ps.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 6 MONTH)
AND ps.ViewCount >= 100
ORDER BY ps.Score DESC, ps.ViewCount DESC
LIMIT 50;
