-- Performance Benchmarking Query
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS AcceptedAnswerId,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,  -- Count of UpVotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,  -- Count of DownVotes
        COALESCE(COUNT(c.Id), 0) AS CommentCount,  -- Count of Comments
        COALESCE(COUNT(b.Id), 0) AS BadgeCount  -- Count of Badges
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        u.DisplayName
    FROM 
        Users u
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.AcceptedAnswerId,
    pm.UpVotes,
    pm.DownVotes,
    pm.CommentCount,
    pm.BadgeCount,
    ur.Reputation,
    ur.DisplayName AS OwnerDisplayName
FROM 
    PostMetrics pm
JOIN 
    UserReputation ur ON pm.OwnerUserId = ur.UserId
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC
LIMIT 100;  -- Limit results for faster performance
