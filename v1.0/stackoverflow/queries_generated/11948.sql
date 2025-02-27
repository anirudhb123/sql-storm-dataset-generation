-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.CommentCount,
    ps.VoteCount,
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.TotalScore
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.PostId = us.UserId 
WHERE 
    ps.VoteCount > 10 -- Only interested in posts with more than 10 votes
ORDER BY 
    ps.VoteCount DESC, 
    us.Reputation DESC
LIMIT 100; -- Limit the results for performance
