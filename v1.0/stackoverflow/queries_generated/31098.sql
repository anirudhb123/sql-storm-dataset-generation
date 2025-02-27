WITH RECURSIVE UserBadges AS (
    SELECT 
        b.UserId,
        b.Name,
        b.Class,
        b.Date,
        1 AS Level
    FROM Badges b
    UNION ALL
    SELECT 
        b.UserId,
        b.Name,
        b.Class,
        b.Date,
        ub.Level + 1
    FROM Badges b
    JOIN UserBadges ub ON b.UserId = ub.UserId
    WHERE b.Date > ub.Date
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
),
PostSummary AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Score
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id
),
PopularPosts AS (
    SELECT 
        ps.Id,
        ps.Title,
        ps.CommentCount,
        ps.Score,
        ROW_NUMBER() OVER (ORDER BY ps.Score DESC, ps.CommentCount DESC) AS PostRank
    FROM PostSummary ps
    WHERE ps.Score > 0
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    p.Title AS PostTitle,
    p.CommentCount,
    p.Score,
    ub.Name AS BadgeName,
    ub.Level AS BadgeLevel,
    RANK() OVER (PARTITION BY u.Id ORDER BY p.Score DESC) AS UserPostRank
FROM TopUsers u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId 
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
JOIN PopularPosts pp ON p.Id = pp.Id
WHERE pp.PostRank <= 10
ORDER BY u.Reputation DESC, pp.Score DESC;

