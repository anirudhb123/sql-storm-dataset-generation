-- Performance Benchmarking Query for StackOverflow Schema

WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount, u.DisplayName
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostsCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.UpVotes) AS TotalUpVotes,
        SUM(p.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT b.Id) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
VoteStatistics AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)

SELECT 
    ps.PostId,
    ps.PostTypeId,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.OwnerDisplayName,
    us.Reputation AS OwnerReputation,
    us.PostsCount AS OwnerPostsCount,
    us.TotalViews AS OwnerTotalViews,
    us.TotalUpVotes AS OwnerTotalUpVotes,
    us.TotalDownVotes AS OwnerTotalDownVotes,
    us.BadgesCount AS OwnerBadgesCount,
    vs.UpVotes AS PostUpVotes,
    vs.DownVotes AS PostDownVotes
FROM 
    PostStatistics ps
LEFT JOIN 
    UserStatistics us ON ps.OwnerDisplayName = us.UserId
LEFT JOIN 
    VoteStatistics vs ON ps.PostId = vs.PostId
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC;
