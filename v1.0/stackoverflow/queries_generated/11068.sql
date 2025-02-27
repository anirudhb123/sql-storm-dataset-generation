-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT bh.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges bh ON bh.UserId = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for posts created in the last year
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        SUM(u.Views) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for users created in the last year
    GROUP BY 
        u.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.VoteCount,
    us.UserId,
    us.DisplayName,
    us.PostsCount,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.TotalViews
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.PostId = us.UserId
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC  -- Ordering by most viewed and highest scored
LIMIT 100;  -- Limit results to top 100 posts
