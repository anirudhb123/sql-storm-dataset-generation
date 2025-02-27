
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        @row_number := IF(@prev_user = p.OwnerUserId, @row_number + 1, 1) AS RankByComments,
        @prev_user := p.OwnerUserId,
        AVG(CASE WHEN v.VoteTypeId = 8 THEN v.BountyAmount END) AS AvgBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_user := NULL) AS vars
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR) 
        AND p.PostTypeId IN (1, 2) 
    GROUP BY p.Id, p.Title, p.PostTypeId, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000 
        AND u.LastAccessDate <= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY)
    GROUP BY u.Id, u.Reputation
),
FinalStats AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ur.UserId,
        ur.Reputation,
        ur.BadgeCount,
        CASE 
            WHEN ps.RankByComments = 1 THEN 'Top Commenter'
            ELSE NULL
        END AS CommenterStatus
    FROM PostStats ps
    LEFT JOIN UserReputation ur ON ps.PostId = ur.UserId
)

SELECT 
    fs.PostId,
    fs.Title,
    fs.CommentCount,
    fs.UpVotes,
    fs.DownVotes,
    fs.Reputation,
    COALESCE(fs.BadgeCount, 0) AS BadgeCount,
    CONCAT('User has ', COALESCE(fs.BadgeCount, 0), ' badges (', 
           CASE WHEN fs.BadgeCount >= 10 THEN 'A badge collector!'
                WHEN fs.BadgeCount >= 5 THEN 'A proficient user!'
                ELSE 'Just starting out!' END, ')') AS BadgeMessage
FROM FinalStats fs
WHERE fs.Reputation IS NOT NULL
ORDER BY fs.UpVotes - fs.DownVotes DESC, fs.CommentCount DESC
LIMIT 50;
