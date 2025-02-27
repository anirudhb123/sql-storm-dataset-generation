-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(p.CreationDate) AS LastActive
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    ps.PostId,
    ps.PostTypeId,
    ps.CommentCount,
    ps.VoteCount,
    ps.LastActive,
    us.UserId,
    us.BadgeCount,
    us.TotalUpVotes,
    us.AvgReputation
FROM 
    PostStats ps
JOIN 
    Users us ON ps.PostTypeId = 1 -- Assuming you want to join with users who are authors of questions
WHERE 
    ps.LastActive BETWEEN NOW() - INTERVAL '30 days' AND NOW()
ORDER BY 
    ps.VoteCount DESC
LIMIT 100;
