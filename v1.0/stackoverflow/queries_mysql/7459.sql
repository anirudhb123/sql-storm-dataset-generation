
WITH UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 END) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 END) AS NetVotes
    FROM Votes v
    GROUP BY v.UserId
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        @rank := @rank + 1 AS Rank
    FROM Posts p, (SELECT @rank := 0) r
    WHERE p.PostTypeId = 1
    ORDER BY p.Score DESC
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId
),
UserReputation AS (
    SELECT 
        u.Id,
        u.Reputation,
        COALESCE(uv.VoteCount, 0) AS TotalVotes,
        COALESCE(pb.BadgeCount, 0) AS TotalBadges
    FROM Users u
    LEFT JOIN UserVotes uv ON u.Id = uv.UserId
    LEFT JOIN PostBadges pb ON u.Id = pb.UserId
)
SELECT 
    ur.Id,
    ur.Reputation,
    ur.TotalVotes,
    ur.TotalBadges,
    pp.Title,
    pp.Score
FROM UserReputation ur
JOIN PopularPosts pp ON ur.Reputation > 5000
WHERE ur.TotalVotes > 50
ORDER BY ur.Reputation DESC, pp.Score DESC
LIMIT 10;
