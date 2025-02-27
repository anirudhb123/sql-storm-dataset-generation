-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT ph.Id) AS EditHistoryCount,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadgeCount,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadgeCount,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    CommentCount,
    VoteCount,
    EditHistoryCount,
    GoldBadgeCount,
    SilverBadgeCount,
    BronzeBadgeCount
FROM 
    PostStats
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 100;
