-- Performance benchmarking query to analyze post statistics and user engagement
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        u.Reputation AS OwnerReputation,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- UpMod votes
        SUM(v.VoteTypeId = 3) AS DownVotes  -- DownMod votes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, u.Reputation
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    ps.CreationDate,
    ps.OwnerReputation,
    us.DisplayName AS OwnerDisplayName,
    us.BadgeCount,
    us.TotalViews AS UserTotalViews,
    us.TotalPosts
FROM 
    PostStats ps
JOIN 
    UserStats us ON ps.OwnerReputation = us.Reputation
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC;
