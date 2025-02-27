-- Performance benchmarking query to analyze active users and their post activity
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        COUNT(c.Id) AS CommentCount,
        SUM(v.CreationDate IS NOT NULL) AS VoteCount,
        SUM(b.Id IS NOT NULL) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 0 -- Consider only users with positive reputation
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    CommentCount,
    VoteCount,
    BadgeCount
FROM 
    UserActivity
ORDER BY 
    PostCount DESC, Reputation DESC
LIMIT 100; -- Limit to top 100 most active users
