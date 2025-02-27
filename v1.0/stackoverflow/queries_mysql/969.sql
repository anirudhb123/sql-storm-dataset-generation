
WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        DisplayName, 
        Reputation, 
        CASE 
            WHEN Reputation < 500 THEN 'Newbie'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Intermediate'
            WHEN Reputation > 1000 THEN 'Expert'
            ELSE 'Unknown'
        END AS ReputationLevel
    FROM Users
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        @row_number := IF(@prev_post_type = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type := p.PostTypeId
    FROM Posts p
    CROSS JOIN (SELECT @row_number := 0, @prev_post_type := NULL) AS vars
    WHERE p.Score > 0
    ORDER BY p.PostTypeId, p.Score DESC
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM Comments c
    GROUP BY c.PostId
),
PostBadges AS (
    SELECT 
        p.Id AS PostId,
        COUNT(b.Id) AS BadgeCount
    FROM Posts p
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    GROUP BY p.Id
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.ReputationLevel,
    pp.PostId,
    pp.Title,
    pp.Score,
    pp.ViewCount,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(pb.BadgeCount, 0) AS BadgeCount
FROM UserReputation up
JOIN PopularPosts pp ON up.UserId = pp.OwnerUserId
LEFT JOIN PostComments pc ON pp.PostId = pc.PostId
LEFT JOIN PostBadges pb ON pp.PostId = pb.PostId
WHERE pp.Rank <= 5
ORDER BY up.Reputation DESC, pp.Score DESC;
