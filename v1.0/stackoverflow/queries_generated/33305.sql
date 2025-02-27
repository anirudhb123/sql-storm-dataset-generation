WITH RECURSIVE UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        0 AS Level
    FROM 
        Users u
    UNION ALL
    SELECT 
        u.Id,
        (u.Reputation + (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id)) * 2 AS Reputation,
        Level + 1
    FROM 
        Users u
    JOIN 
        UserReputation ur ON ur.UserId = u.Id
    WHERE 
        ur.Level < 10
),
RecentPostUpdates AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreatedDate,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
HighScoringPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.Score > 10
    GROUP BY 
        p.Id, p.Title
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    ub.HighestClass,
    hp.Title,
    hp.UpVotes,
    hp.DownVotes,
    hp.CommentCount,
    CASE 
        WHEN hp.UpVotes > hp.DownVotes THEN 'High Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
JOIN 
    RecentPostUpdates rpu ON u.Id = rpu.UserDisplayName
JOIN 
    HighScoringPosts hp ON rpu.PostId = hp.PostId
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users)
    AND rpu.rn = 1
ORDER BY 
    u.Reputation DESC, hp.UpVotes DESC
LIMIT 50;
