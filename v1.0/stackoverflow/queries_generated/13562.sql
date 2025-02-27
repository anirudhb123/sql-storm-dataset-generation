-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2 AND a.AcceptedAnswerId IS NOT NULL
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    us.UserId,
    us.Reputation,
    us.BadgeCount,
    us.TotalBounty,
    us.PostCount,
    us.CommentCount,
    us.AcceptedAnswers,
    ROW_NUMBER() OVER (ORDER BY us.Reputation DESC) AS Rank
FROM 
    UserStats us
ORDER BY 
    us.Reputation DESC;
