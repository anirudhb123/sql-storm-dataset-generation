WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) as PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation, COUNT(DISTINCT rp.Id) AS PostCount
    FROM Users u
    JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE rp.PostRank <= 5
    GROUP BY u.Id, u.DisplayName, u.Reputation
)
SELECT u.Id, u.DisplayName, u.Reputation, u.PostCount,
       COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
       COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
       COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
FROM TopUsers u
LEFT JOIN Badges b ON u.Id = b.UserId
GROUP BY u.Id, u.DisplayName, u.Reputation, u.PostCount
ORDER BY u.Reputation DESC, u.PostCount DESC;
