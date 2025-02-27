
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
RecentEdits AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.UserDisplayName AS Editor,
        ph.CreationDate AS EditDate,
        ph.Comment,
        @row_num := IF(@prev_id = p.Id, @row_num + 1, 1) AS EditRank,
        @prev_id := p.Id
    FROM Posts p
    INNER JOIN PostHistory ph ON p.Id = ph.PostId
    CROSS JOIN (SELECT @row_num := 0, @prev_id := NULL) AS init
    WHERE ph.PostHistoryTypeId IN (4, 5, 6)
    ORDER BY p.Id, ph.CreationDate DESC
),
TopUsers AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
    HAVING COUNT(*) > 3
)
SELECT 
    u.DisplayName,
    u.Reputation,
    us.TotalVotes,
    us.UpVotes,
    us.DownVotes,
    re.Title,
    re.Editor,
    re.EditDate,
    CASE WHEN re.EditRank = 1 THEN 'Latest Edit' ELSE 'Earlier Edit' END AS EditStatus,
    tb.BadgeCount
FROM Users u
LEFT JOIN UserVoteStats us ON u.Id = us.UserId
LEFT JOIN RecentEdits re ON u.DisplayName = re.Editor
LEFT JOIN TopUsers tb ON u.Id = tb.UserId
WHERE u.Reputation >= 1000
AND (us.TotalVotes IS NULL OR us.TotalVotes > 10)
ORDER BY u.Reputation DESC, IFNULL(us.TotalVotes, 0) DESC
LIMIT 50;
