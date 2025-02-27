
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        @row_number := IF(@prev_reputation = u.Reputation, @row_number, @row_number + 1) AS Rank,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        @prev_reputation := u.Reputation
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    CROSS JOIN (SELECT @row_number := 0, @prev_reputation := NULL) AS vars
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.Id END) AS CloseReopenCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY p.Id, p.Title, p.OwnerUserId
),
RankedActivePosts AS (
    SELECT 
        ap.PostId,
        ap.Title,
        ap.OwnerUserId,
        ap.CommentCount,
        ap.PositiveScoreCount,
        ap.CloseReopenCount,
        @owner_post_rank := IF(@prev_owner = ap.OwnerUserId, @owner_post_rank + 1, 1) AS OwnerPostRank,
        @prev_owner := ap.OwnerUserId
    FROM ActivePosts ap
    CROSS JOIN (SELECT @owner_post_rank := 0, @prev_owner := NULL) AS vars
),
UserPostStats AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        COALESCE(SUM(rp.CommentCount), 0) AS TotalComments,
        COALESCE(SUM(rp.PositiveScoreCount), 0) AS TotalPositiveScorePosts,
        COALESCE(SUM(rp.CloseReopenCount), 0) AS TotalCloseReopenActions
    FROM UserReputation ur
    LEFT JOIN RankedActivePosts rp ON ur.UserId = rp.OwnerUserId
    GROUP BY ur.UserId, ur.DisplayName, ur.Reputation
)
SELECT 
    ups.DisplayName,
    ups.Reputation,
    ups.TotalComments,
    ups.TotalPositiveScorePosts,
    ups.TotalCloseReopenActions,
    CASE 
        WHEN ups.Reputation >= 1000 THEN 'Veteran'
        WHEN ups.Reputation BETWEEN 500 AND 999 THEN 'Experienced'
        WHEN ups.Reputation < 500 THEN 'Novice'
        ELSE 'Unknown'
    END AS UserType,
    GROUP_CONCAT(DISTINCT CASE WHEN b.Class = 1 THEN b.Name END) AS GoldBadges,
    GROUP_CONCAT(DISTINCT CASE WHEN b.Class = 2 THEN b.Name END) AS SilverBadges,
    GROUP_CONCAT(DISTINCT CASE WHEN b.Class = 3 THEN b.Name END) AS BronzeBadges
FROM UserPostStats ups
LEFT JOIN Badges b ON ups.UserId = b.UserId
GROUP BY ups.DisplayName, ups.Reputation, ups.TotalComments, ups.TotalPositiveScorePosts, ups.TotalCloseReopenActions
ORDER BY ups.Reputation DESC, ups.TotalComments DESC;
