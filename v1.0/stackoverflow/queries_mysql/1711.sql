
WITH UserStats AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        @row_number := @row_number + 1 AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS JOIN (SELECT @row_number := 0) r
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), HighReputationUsers AS (
    SELECT 
        Id, 
        DisplayName, 
        Reputation,
        UpVotes, 
        DownVotes, 
        PostCount, 
        CommentCount,
        UserRank
    FROM 
        UserStats
    WHERE 
        Reputation > 1000
), UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Class
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
), RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        @recent_row_number := IF(@prev_user_id = p.OwnerUserId, @recent_row_number + 1, 1) AS RecentPostRank,
        @prev_user_id := p.OwnerUserId
    FROM 
        Posts p
    CROSS JOIN (SELECT @recent_row_number := 0, @prev_user_id := NULL) r
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    COALESCE(b.BadgeName, 'No Badge') AS Badge,
    COUNT(DISTINCT rp.Id) AS RecentPostCount,
    SUM(CASE WHEN rp.RecentPostRank <= 5 THEN 1 ELSE 0 END) AS TopRecentPosts,
    u.UpVotes,
    u.DownVotes
FROM 
    HighReputationUsers u
LEFT JOIN 
    UsersWithBadges b ON u.Id = b.UserId
LEFT JOIN 
    RecentPosts rp ON u.Id = rp.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, b.BadgeName, u.UpVotes, u.DownVotes
ORDER BY 
    u.Reputation DESC, UserName ASC
LIMIT 10 OFFSET 0;
