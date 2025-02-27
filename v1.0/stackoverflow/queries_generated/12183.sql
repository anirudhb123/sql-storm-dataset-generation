-- Performance benchmarking query to analyze post statistics and user interactions
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(AnswerCount, 0) AS AnswerCount,
        COALESCE(CommentCount, 0) AS CommentCount,
        COALESCE(FavoriteCount, 0) AS FavoriteCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, AnswerCount, CommentCount, FavoriteCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostsCount
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
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.VoteCount,
    us.UserId,
    us.DisplayName AS OwnerDisplayName,
    us.Reputation AS OwnerReputation,
    us.BadgeCount,
    us.PostsCount
FROM 
    PostStats ps
JOIN 
    Users u ON ps.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
JOIN 
    UserStats us ON us.UserId = u.Id
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC;
