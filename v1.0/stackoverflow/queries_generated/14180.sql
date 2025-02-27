-- Performance benchmarking query for StackOverflow schema
-- This query retrieves various metrics for posts, users, and comments to analyze performance
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(v.CreationDate) AS LastVoteDate,
        p.CreationDate AS PostCreationDate,
        p.ViewCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        p.Id, p.Title, pt.Name, p.CreationDate, p.ViewCount
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.PostType,
    pm.CommentCount,
    pm.VoteCount,
    pm.UpVotes,
    pm.DownVotes,
    pm.LastVoteDate,
    pm.PostCreationDate,
    pm.ViewCount,
    um.UserId,
    um.Reputation,
    um.BadgeCount,
    um.PostsCount,
    um.CommentsCount
FROM 
    PostMetrics pm
JOIN 
    Users u ON pm.PostId = u.Id
JOIN 
    UserMetrics um ON u.Id = um.UserId
ORDER BY 
    pm.ViewCount DESC, pm.PostCreationDate DESC;
