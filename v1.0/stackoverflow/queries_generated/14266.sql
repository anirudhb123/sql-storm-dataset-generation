-- Performance Benchmarking Query for StackOverflow Schema
WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id
),
UserSummary AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
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
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.AnswerCount,
    us.UserId,
    us.BadgeCount,
    us.TotalUpVotes,
    us.TotalDownVotes
FROM 
    PostSummary ps
JOIN 
    Users us ON ps.PostId = us.Id  -- Assume we are matching Posts with Users based on owner
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100;  -- Limiting the results for performance benchmarking
