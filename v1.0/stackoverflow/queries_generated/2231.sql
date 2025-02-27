WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.AnswerCount, p.Score, u.DisplayName AS OwnerDisplayName, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
           COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS Upvotes,
           COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS Downvotes
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON p.Id = v.PostId 
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),
PostDetails AS (
    SELECT rp.Id, rp.Title, rp.AnswerCount, rp.Score, rp.OwnerDisplayName, 
           rp.RankScore, rp.Upvotes, rp.Downvotes,
           CASE 
               WHEN rp.AnswerCount = 0 THEN 'No Answers'
               WHEN rp.Score > 10 THEN 'Popular'
               ELSE 'Needs Attention'
           END AS Status
    FROM RankedPosts rp
    WHERE rp.RankScore <= 5 
),
UserBadges AS (
    SELECT b.UserId, COUNT(*) as BadgeCount
    FROM Badges b
    WHERE b.Class = 1
    GROUP BY b.UserId
),
TopUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation, COALESCE(ub.BadgeCount, 0) AS GoldBadges
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    WHERE u.Reputation > 1000
)
SELECT pd.Title, pd.Status, pd.OwnerDisplayName, tu.DisplayName AS TopUser, tu.GoldBadges
FROM PostDetails pd
JOIN TopUsers tu ON pd.OwnerDisplayName = tu.DisplayName
ORDER BY pd.Score DESC, pd.AnswerCount DESC
LIMIT 10;

