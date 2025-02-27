-- Performance Benchmarking SQL Query
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(v.Value, 0)) AS TotalVotes,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
            v.PostId, 
            SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 WHEN vt.Name = 'DownMod' THEN -1 ELSE 0 END) AS Value
         FROM 
            Votes v
         JOIN 
            VoteTypes vt ON v.VoteTypeId = vt.Id
         GROUP BY v.PostId) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation
), PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(v.Value, 0)) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
            v.PostId, 
            SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 WHEN vt.Name = 'DownMod' THEN -1 ELSE 0 END) AS Value
         FROM 
            Votes v
         JOIN 
            VoteTypes vt ON v.VoteTypeId = vt.Id
         GROUP BY v.PostId) v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

-- Final benchmarking result set
SELECT 
    us.UserId,
    us.Reputation,
    us.PostCount,
    us.TotalVotes,
    us.TotalComments,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.TotalVotes AS PostTotalVotes
FROM 
    UserStats us
JOIN 
    PostStats ps ON us.UserId = ps.OwnerUserId
ORDER BY 
    us.Reputation DESC, ps.ViewCount DESC;
