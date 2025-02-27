-- Performance benchmarking query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,  -- Up votes
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount -- Down votes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month' -- last month filter
    GROUP BY 
        p.Id, p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    u.UserId,
    u.PostCount,
    u.TotalUpVotes,
    u.TotalDownVotes,
    ps.PostId,
    ps.PostTypeId,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVoteCount,
    ps.DownVoteCount
FROM 
    UserStats u
JOIN 
    PostStats ps ON u.UserId = ps.PostId
ORDER BY 
    u.PostCount DESC, ps.VoteCount DESC
LIMIT 100; -- returning top 100 for performance analysis
