-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id 
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())  -- Filter for the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.UpVotes) AS TotalUpVotes,
        SUM(p.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
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
    us.TotalUpVotes,
    us.TotalDownVotes
FROM 
    PostStats ps
JOIN 
    UserStats us ON us.UserId = ps.PostId  -- This would typically align with the post's owner
ORDER BY 
    ps.CreationDate DESC
OPTION (RECOMPILE);  -- Use for parameter sniffing prevention when benchmarking
