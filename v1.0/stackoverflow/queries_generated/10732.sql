-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1  -- Only count answers for questions
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= '2022-01-01'  -- Filtering for posts created in 2022
    GROUP BY 
        p.Id, pt.Name
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount > 0 THEN 1 ELSE 0 END) AS ActivePosts,
        SUM(b.Id IS NOT NULL) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.PostType,
    ps.CommentCount,
    ps.AnswerCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.CreationDate,
    ps.LastActivityDate,
    ps.ViewCount,
    ps.Score,
    ua.PostCount,
    ua.ActivePosts,
    ua.BadgeCount
FROM 
    PostStats ps
LEFT JOIN 
    UserActivity ua ON ps.OwnerUserId = ua.UserId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100;  -- Limiting the result set for performance
