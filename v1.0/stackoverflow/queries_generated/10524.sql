-- Performance Benchmarking Query

WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.BadgeCount,
    ur.UpVotes AS UserUpVotes,
    ur.DownVotes AS UserDownVotes,
    ur.TotalViews AS UserTotalViews,
    ur.TotalPosts AS UserTotalPosts,
    ur.TotalComments AS UserTotalComments,
    ps.PostId,
    ps.Title AS PostTitle,
    ps.CreationDate AS PostCreationDate,
    ps.Score AS PostScore,
    ps.ViewCount AS PostViewCount,
    ps.CommentCount AS PostCommentCount,
    ps.UpVotes AS PostUpVotes,
    ps.DownVotes AS PostDownVotes
FROM 
    UserReputation ur
JOIN 
    PostStatistics ps ON ur.UserId = ps.PostId
ORDER BY 
    ur.Reputation DESC, ps.Score DESC;
