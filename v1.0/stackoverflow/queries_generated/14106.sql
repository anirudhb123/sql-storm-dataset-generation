-- Performance Benchmarking Query
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        AVG(p.Score) AS AverageScore,
        MAX(p.CreationDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.AverageScore,
    ps.LastActivityDate,
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.TotalUpVotes,
    us.TotalDownVotes
FROM 
    PostStatistics ps
JOIN 
    Users us ON ps.PostId = us.AccountId -- Assuming Adjacent Post Ownership; adjust join condition as necessary
ORDER BY 
    ps.LastActivityDate DESC,
    ps.AverageScore DESC
LIMIT 100; -- Limiting the result set for performance benchmarking
