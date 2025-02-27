WITH PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(ps.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(ps.DownVotes, 0)) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostVoteSummary ps ON p.Id = ps.PostId
    GROUP BY u.Id
)
SELECT 
    u.UserId,
    u.Reputation,
    u.PostCount,
    u.TotalUpVotes,
    u.TotalDownVotes,
    (u.TotalUpVotes - u.TotalDownVotes) AS NetVotes,
    CASE 
        WHEN u.Reputation >= 10000 THEN 'Gold'
        WHEN u.Reputation >= 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS Badge
FROM UserReputation u
WHERE u.PostCount > 0
ORDER BY u.NetVotes DESC, u.Reputation DESC
LIMIT 10;
