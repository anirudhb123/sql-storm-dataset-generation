WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank
    FROM Posts p
    WHERE p.ViewCount > 100
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.Score, 
    rp.CreationDate, 
    us.DisplayName AS OwnerName, 
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    COALESCE(pvc.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pvc.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM RankedPosts rp
JOIN Users us ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = us.Id)
LEFT JOIN PostVoteCounts pvc ON rp.PostId = pvc.PostId
WHERE us.Reputation BETWEEN 1000 AND 5000
ORDER BY rp.Score DESC, us.DisplayName ASC
LIMIT 10;
