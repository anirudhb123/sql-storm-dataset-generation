
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        @row_num := IF(@prev_user = p.OwnerUserId, @row_num + 1, 1) AS PostRank,
        @prev_user := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId,
        (SELECT @row_num := 0, @prev_user := NULL) AS init
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, p.Tags
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        u.Reputation,
        COUNT(r.PostId) AS RecentPostCount,
        SUM(c.CommentCount) AS TotalComments,
        SUM(r.VoteCount) AS TotalVotes
    FROM 
        Users u
    JOIN 
        RecentPosts r ON u.Id = r.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON r.PostId = c.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    au.UserId,
    au.DisplayName,
    au.Reputation,
    au.RecentPostCount,
    au.TotalComments,
    au.TotalVotes,
    ub.BadgeCount,
    ub.BadgeNames
FROM 
    ActiveUsers au
LEFT JOIN 
    UserBadges ub ON au.UserId = ub.UserId
ORDER BY 
    au.Reputation DESC, 
    au.TotalVotes DESC
LIMIT 10;
