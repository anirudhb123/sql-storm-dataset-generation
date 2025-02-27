WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.Score,
           p.OwnerUserId,
           DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
           COUNT(c.Id) FILTER (WHERE c.UserId IS NOT NULL) AS CommentCount
    FROM Posts p 
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.Score, p.OwnerUserId
),  

UserBadges AS (
    SELECT u.Id AS UserId,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
           COUNT(DISTINCT b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
), 

PostLinkSummary AS (
    SELECT pl.PostId,
           COUNT(*) AS LinkCount,
           STRING_AGG(DISTINCT pt.Name, ', ') AS LinkTypes
    FROM PostLinks pl
    JOIN LinkTypes pt ON pl.LinkTypeId = pt.Id
    GROUP BY pl.PostId
)

SELECT p.Title,
       p.Score,
       p.RankScore,
       CASE 
           WHEN ub.TotalBadges IS NULL THEN 'No Badges'
           ELSE CONCAT('Gold: ', COALESCE(ub.GoldBadges, 0), ', Silver: ', COALESCE(ub.SilverBadges, 0), ', Bronze: ', COALESCE(ub.BronzeBadges, 0))
       END AS BadgeSummary,
       COALESCE(h.LinkCount, 0) AS TotalLinks,
       h.LinkTypes,
       p.CommentCount AS NumberOfComments,
       COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId IN (2, 3)) AS UpDownVotes
FROM RankedPosts p
LEFT JOIN UserBadges ub ON p.OwnerUserId = ub.UserId
LEFT JOIN PostLinkSummary h ON p.Id = h.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
WHERE p.RankScore <= 5 AND p.Score > 10
GROUP BY p.Title, p.Score, p.RankScore, ub.TotalBadges, h.LinkCount, h.LinkTypes, p.CommentCount
ORDER BY p.Score DESC, p.Title
LIMIT 100;

