
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        @row_number := @row_number + 1 AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    CROSS JOIN (SELECT @row_number := 0) AS rn
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
CombinedStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.BadgeCount,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        pi.PostId,
        pi.Title,
        pi.UpVotes,
        pi.DownVotes,
        pi.CommentCount,
        pi.CloseCount,
        CASE 
            WHEN us.Reputation > 1000 THEN 'High'
            WHEN us.Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low' 
        END AS ReputationTier,
        @post_rank := IF(@current_user_id = us.UserId, @post_rank + 1, 1) AS PostRank,
        @current_user_id := us.UserId
    FROM 
        UserStats us
    LEFT JOIN 
        PostInteractions pi ON us.UserId = pi.OwnerUserId
    CROSS JOIN (SELECT @post_rank := 0, @current_user_id := NULL) AS pr
)
SELECT 
    cs.UserId,
    cs.DisplayName,
    cs.Reputation,
    cs.BadgeCount,
    cs.GoldBadges,
    cs.SilverBadges,
    cs.BronzeBadges,
    GROUP_CONCAT(DISTINCT cs.Title) AS UserPosts,
    SUM(cs.UpVotes) AS TotalUpVotes,
    SUM(cs.DownVotes) AS TotalDownVotes,
    SUM(cs.CommentCount) AS TotalComments,
    SUM(cs.CloseCount) AS TotalCloses,
    COUNT(*) AS PostCount,
    COUNT(DISTINCT pi.PostId) AS ClosedPostCount
FROM 
    CombinedStats cs
LEFT JOIN 
    PostInteractions pi ON cs.PostId = pi.PostId
GROUP BY 
    cs.UserId, cs.DisplayName, cs.Reputation, cs.BadgeCount, cs.GoldBadges, cs.SilverBadges, cs.BronzeBadges
HAVING 
    SUM(cs.UpVotes) > 10 OR COUNT(DISTINCT cs.PostId) > 5
ORDER BY 
    TotalUpVotes DESC, PostCount DESC;
