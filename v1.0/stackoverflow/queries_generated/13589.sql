-- Performance Benchmarking Query
-- This query retrieves various metrics regarding posts, votes, and users for performance evaluation.

WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT c.Id) AS TotalComments,
        p.CreationDate,
        p.LastActivityDate,
        DATEDIFF(MINUTE, p.CreationDate, GETDATE()) AS AgeInMinutes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate, p.LastActivityDate
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)

SELECT 
    pm.PostId,
    pm.PostTypeId,
    pm.VoteCount,
    pm.UpVotes,
    pm.DownVotes,
    pm.TotalComments,
    um.UserId,
    um.Reputation,
    um.PostCount,
    um.BadgeCount,
    pm.AgeInMinutes
FROM 
    PostMetrics pm
JOIN 
    Users u ON pm.OwnerUserId = u.Id
JOIN 
    UserMetrics um ON u.Id = um.UserId
ORDER BY 
    pm.VoteCount DESC, pm.PostId ASC;
