
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        @row_number := IF(@prev_reputation = u.Reputation, @row_number, @row_number + 1) AS ReputationRank,
        @prev_reputation := u.Reputation
    FROM 
        Users u, (SELECT @row_number := 0, @prev_reputation := NULL) AS vars
    ORDER BY 
        u.Reputation DESC
), PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
    HAVING 
        COUNT(c.Id) > 5
), RecentHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        p.Title AS PostTitle,
        @rank := IF(@prev_post_id = ph.PostId, @rank + 1, 1) AS VersionRank,
        @prev_post_id := ph.PostId
    FROM 
        PostHistory ph, Posts p, (SELECT @rank := 0, @prev_post_id := NULL) AS vars
    WHERE 
        ph.PostId = p.Id AND 
        ph.CreationDate >= NOW() - INTERVAL 1 MONTH
    ORDER BY 
        ph.PostId, ph.CreationDate DESC
)

SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    pp.PostId,
    pp.Title AS PostTitle,
    pp.ViewCount,
    pp.Score,
    pp.CommentCount,
    rh.CreationDate AS RecentChangeDate,
    rh.Comment AS RecentComment,
    rh.VersionRank
FROM 
    UserReputation ur
JOIN 
    PopularPosts pp ON ur.UserId IN (
        SELECT OwnerUserId FROM Posts WHERE Id IN (
            SELECT PostId FROM PostHistory WHERE PostHistoryTypeId IN (10, 11) 
        )
    )
LEFT JOIN 
    RecentHistory rh ON pp.PostId = rh.PostId AND rh.VersionRank = 1
WHERE 
    ur.Reputation > 1000 
ORDER BY 
    pp.Score DESC, ur.Reputation DESC
LIMIT 100;
