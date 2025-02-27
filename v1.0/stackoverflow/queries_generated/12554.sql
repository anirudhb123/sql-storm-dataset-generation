-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        DATEDIFF(NOW(), p.CreationDate) AS PostAgeDays
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Within the last year
    GROUP BY 
        p.Id, p.Score, p.ViewCount, p.CreationDate
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COUNT(p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    ps.PostId,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    us.UserId,
    us.Reputation,
    us.BadgeCount,
    us.PostCount,
    us.TotalBounty,
    ps.PostAgeDays
FROM 
    PostStats ps
JOIN 
    Users u ON ps.PostId = u.Id  -- Here, you might want to modify join predicate based on the actual relation needed
JOIN 
    UserStats us ON u.Id = us.UserId
ORDER BY 
    ps.Score DESC, us.Reputation DESC;  -- Sorts results by post score and user reputation
