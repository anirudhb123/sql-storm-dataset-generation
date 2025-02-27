
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        @row_number := IF(@prev_owner = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @prev_owner := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId,
    (SELECT @row_number := 0, @prev_owner := NULL) AS vars
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.OwnerUserId
),
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.UpVotes - rp.DownVotes > 0 THEN 'Positive'
            WHEN rp.UpVotes - rp.DownVotes < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment,
        CASE 
            WHEN rp.Rank = 1 THEN 'Most Recent Post'
            ELSE 'Older Post'
        END AS PostRecency
    FROM RankedPosts rp
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT ps.PostId) AS PostsCount,
        SUM(CASE WHEN ps.Sentiment = 'Positive' THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN ps.Sentiment = 'Negative' THEN 1 ELSE 0 END) AS NegativePosts
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN PostSummary ps ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
    GROUP BY u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.PostsCount,
    us.PositivePosts,
    us.NegativePosts,
    CASE 
        WHEN us.Reputation > 1000 THEN 'Expert'
        WHEN us.Reputation BETWEEN 500 AND 1000 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel,
    GROUP_CONCAT(CONCAT_WS(' - ', ps.Title, ps.Sentiment)) AS PostSummaries
FROM UserStats us
LEFT JOIN PostSummary ps ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
GROUP BY us.UserId, us.DisplayName, us.Reputation, us.GoldBadges, us.SilverBadges, us.BronzeBadges, us.PostsCount, us.PositivePosts, us.NegativePosts
ORDER BY us.Reputation DESC;
