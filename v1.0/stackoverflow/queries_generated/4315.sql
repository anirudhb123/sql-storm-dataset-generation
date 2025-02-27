WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) AS NetVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
    HAVING COUNT(c.Id) > 5
),
RankedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.ViewCount,
        pd.OwnerUserId,
        RANK() OVER (ORDER BY pd.Score DESC) AS PostRank
    FROM PostDetails pd
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.NetVotes,
    us.BadgeCount,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.PostRank,
    COALESCE(cp.CreationDate, 'Not Closed') AS ClosureDate
FROM UserStats us
JOIN RankedPosts rp ON us.UserId = rp.OwnerUserId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE us.Reputation > 1000
ORDER BY us.Reputation DESC, rp.Score DESC;
