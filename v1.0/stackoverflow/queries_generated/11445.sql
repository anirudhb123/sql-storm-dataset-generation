-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = p.Id) AS EditHistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
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
    ps.CreationDate,
    ps.CommentCount,
    ps.VoteCount,
    ps.EditHistoryCount,
    us.UserId,
    us.BadgeCount,
    us.TotalUpVotes,
    us.TotalDownVotes
FROM 
    PostStats ps
JOIN 
    Users u ON ps.OwnerUserId = u.Id
JOIN 
    UserStats us ON u.Id = us.UserId
ORDER BY 
    ps.PostId;
