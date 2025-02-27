-- Performance benchmarking query for the Stack Overflow schema
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        MAX(p.CreationDate) AS LastActivityDate,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.UpVotes) AS TotalUpVotes,
        SUM(p.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostStats p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    ps.PostId,
    ps.PostTypeId,
    us.UserId,
    us.Reputation,
    ps.CommentCount,
    ps.VoteCount,
    ps.LastActivityDate,
    us.BadgeCount,
    us.TotalViews,
    us.TotalUpVotes,
    us.TotalDownVotes
FROM 
    PostStats ps
JOIN 
    Users us ON ps.OwnerUserId = us.Id
ORDER BY 
    ps.LastActivityDate DESC;
