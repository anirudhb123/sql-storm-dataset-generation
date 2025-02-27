-- Performance benchmarking query for analyzing posts, votes, and user activity

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        COALESCE(SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(v.Id IS NOT NULL) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.TotalVotes,
    ps.UpVotes,
    ps.DownVotes,
    ua.UserId,
    ua.DisplayName,
    ua.PostsCreated,
    ua.CommentsMade,
    ua.TotalBounties,
    ua.TotalVotes AS UserVotes
FROM 
    PostStats ps
JOIN 
    Users u ON ps.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
JOIN 
    UserActivity ua ON u.Id = ua.UserId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
