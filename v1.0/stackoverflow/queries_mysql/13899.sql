
WITH BenchmarkData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(b.Id) AS BadgeCount,
        u.Reputation,
        p.Score,
        p.ViewCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.Reputation, p.Score, p.ViewCount
)

SELECT 
    PostId,
    Title,
    CreationDate,
    CommentCount,
    VoteCount,
    BadgeCount,
    Reputation,
    Score,
    ViewCount,
    (SELECT COUNT(*) FROM BenchmarkData bd2 WHERE bd2.ViewCount > bd1.ViewCount) + 1 AS ViewRank,
    (SELECT COUNT(*) FROM BenchmarkData bd2 WHERE bd2.VoteCount > bd1.VoteCount) + 1 AS VoteRank,
    (SELECT COUNT(*) FROM BenchmarkData bd2 WHERE bd2.CommentCount > bd1.CommentCount) + 1 AS CommentRank
FROM 
    BenchmarkData bd1
ORDER BY 
    CreationDate DESC
LIMIT 100;
