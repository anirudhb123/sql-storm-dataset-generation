-- Performance Benchmarking SQL Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(bs.Count) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges bs ON u.Id = bs.UserId
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
    ps.UpVotes,
    ps.DownVotes,
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.TotalViews,
    us.TotalScore
FROM 
    PostStats ps
JOIN 
    Users us ON ps.UserId = us.Id
ORDER BY 
    ps.CreationDate DESC
LIMIT 100; -- limiting for performance benchmarking
