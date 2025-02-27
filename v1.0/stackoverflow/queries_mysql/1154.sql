
WITH UserBadgeCounts AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount, 
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ubc.BadgeCount, 0) AS BadgeCount,
        u.Reputation,
        @row_number := IF(@prev_badge_count = COALESCE(ubc.BadgeCount, 0) AND @prev_reputation = u.Reputation, @row_number, @row_number + 1) AS UserRank,
        @prev_badge_count := COALESCE(ubc.BadgeCount, 0),
        @prev_reputation := u.Reputation
    FROM Users u
    LEFT JOIN UserBadgeCounts ubc ON u.Id = ubc.UserId
    CROSS JOIN (SELECT @row_number := 0, @prev_badge_count := NULL, @prev_reputation := NULL) r
    WHERE u.Reputation > 100 
),
PostVoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(CASE WHEN VoteTypeId = 10 THEN 1 END) AS Deletions
    FROM Votes
    GROUP BY PostId
),
PostsWithVoteInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COALESCE(pvs.Upvotes, 0) AS Upvotes,
        COALESCE(pvs.Downvotes, 0) AS Downvotes,
        COALESCE(pvs.Deletions, 0) AS Deletions,
        @recent_post_rank := @recent_post_rank + 1 AS RecentPostRank
    FROM Posts p
    CROSS JOIN (SELECT @recent_post_rank := 0) r
    LEFT JOIN PostVoteSummary pvs ON p.Id = pvs.PostId
)
SELECT 
    tu.DisplayName,
    tu.BadgeCount,
    tu.Reputation,
    COUNT(pwv.PostId) AS PostsContributed,
    SUM(pwv.Upvotes) AS TotalUpvotes,
    SUM(pwv.Downvotes) AS TotalDownvotes
FROM TopUsers tu
LEFT JOIN PostsWithVoteInfo pwv ON tu.Id = pwv.OwnerUserId
WHERE tu.UserRank <= 10 
GROUP BY 
    tu.Id, 
    tu.DisplayName, 
    tu.BadgeCount, 
    tu.Reputation
ORDER BY 
    TotalUpvotes DESC, 
    TotalDownvotes ASC;
