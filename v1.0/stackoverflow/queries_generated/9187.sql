WITH RecentPosts AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.Score, p.ViewCount, COUNT(c.Id) AS CommentCount, 
           COUNT(DISTINCT b.Id) AS BadgeCount, 
           ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN PostsTags pt ON p.Id = pt.PostId
    LEFT JOIN Tags t ON pt.TagId = t.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id
),
UserStatistics AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation, 
           COUNT(DISTINCT p.Id) AS PostCount, 
           SUM(COALESCE(p.Score, 0)) AS TotalScore, 
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostDetails AS (
    SELECT rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.CommentCount, rp.Tags,
           us.UserId, us.DisplayName AS OwnerDisplayName, us.Reputation AS OwnerReputation,
           us.PostCount AS OwnerPostCount, us.TotalScore AS OwnerTotalScore,
           us.GoldBadges AS OwnerGoldBadges, us.SilverBadges AS OwnerSilverBadges, us.BronzeBadges AS OwnerBronzeBadges
    FROM RecentPosts rp
    JOIN UserStatistics us ON rp.PostId = us.UserId
)
SELECT pd.*, 
       ROW_NUMBER() OVER (ORDER BY pd.Score DESC, pd.ViewCount DESC) AS Rank 
FROM PostDetails pd
ORDER BY pd.CreationDate DESC
LIMIT 100;
