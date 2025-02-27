WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS RankByComments,
        AVG(v.BountyAmount) FILTER (WHERE v.VoteTypeId = 8) AS AvgBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) -- Only questions and answers
    GROUP BY p.Id
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
        AND u.LastAccessDate <= NOW() - INTERVAL '30 days'
    GROUP BY u.Id
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
FETCH FIRST 50 ROWS ONLY;

-- This comprehensive query collects post statistics including user reputation and badges held,
-- while elegantly employing CTEs for better organization and readability. It leverages conditional logic
-- and ranking functions to create a meaningful output that reflects user engagement and contribution quality.
