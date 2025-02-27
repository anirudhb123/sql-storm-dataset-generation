-- Performance benchmarking query to analyze Posts and associated Users, Votes, and Comments

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        COALESCE(u.Reputation, 0) AS OwnerReputation,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id) AS VoteCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.PostTypeId,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.OwnerReputation,
    ps.VoteCount,
    ps.CommentCount,
    (SELECT COUNT(DISTINCT b.Id) FROM Badges b WHERE b.UserId = ps.OwnerUserId) AS BadgeCount
FROM 
    PostStats ps
WHERE 
    ps.CreationDate >= NOW() - INTERVAL '1 year'
ORDER BY 
    ps.Score DESC,
    ps.ViewCount DESC
LIMIT 100;
