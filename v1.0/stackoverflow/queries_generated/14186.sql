-- Performance Benchmarking Query to Analyze Posts and Related Data
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        COALESCE(SUM(c.Id) OVER (PARTITION BY p.Id), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.CommentCount,
    ua.UserId,
    ua.DisplayName AS PostOwner,
    ua.PostsCreated,
    ua.CommentsMade,
    ua.TotalViews
FROM 
    PostStats ps
JOIN 
    UserActivity ua ON ps.PostId = ua.UserId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100;
