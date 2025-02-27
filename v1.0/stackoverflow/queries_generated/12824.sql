-- Performance Benchmarking Query

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        DATEDIFF(second, p.CreationDate, GETDATE()) AS AgeInSeconds
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
        SUM(u.Views) AS TotalViews,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
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
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.AgeInSeconds,
    us.UserId,
    us.BadgeCount,
    us.TotalViews,
    us.TotalUpVotes,
    us.TotalDownVotes
FROM 
    PostStats ps
JOIN 
    Users u ON ps.PostId = u.Id
JOIN 
    UserStats us ON u.Id = us.UserId
ORDER BY 
    ps.Score DESC, 
    ps.AgeInSeconds ASC;
