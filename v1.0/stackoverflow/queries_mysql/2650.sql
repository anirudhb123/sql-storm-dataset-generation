
WITH UserBadgeCount AS (
    SELECT UserId, COUNT(*) AS TotalBadges
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(pc.Count, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        pb.TotalBadges
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS Count
        FROM Comments
        GROUP BY PostId
    ) pc ON p.Id = pc.PostId
    LEFT JOIN (
        SELECT ParentId, COUNT(*) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN UserBadgeCount pb ON p.OwnerUserId = pb.UserId
    WHERE p.CreationDate > NOW() - INTERVAL 1 YEAR
),
RankedPosts AS (
    SELECT 
        ps.*,
        @row_number:=IF(@prev_badge = TotalBadges, @row_number + 1, 1) AS BadgeRank,
        @prev_badge:=TotalBadges
    FROM PostStats ps, (SELECT @row_number:=0, @prev_badge:=NULL) AS vars
    ORDER BY TotalBadges, ps.Score DESC
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.AnswerCount,
    rp.TotalBadges,
    CASE 
        WHEN rp.BadgeRank <= 5 THEN 'Top Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM RankedPosts rp
WHERE rp.Score > (
    SELECT AVG(Score)
    FROM Posts
    WHERE CreationDate > NOW() - INTERVAL 1 YEAR
)
ORDER BY PostCategory, rp.Score DESC
LIMIT 100;
