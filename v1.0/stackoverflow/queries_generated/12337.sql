-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(b.Class), 0) AS BadgeCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON b.UserId = p.OwnerUserId
    GROUP BY p.Id, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount
)
SELECT 
    COUNT(PostId) AS TotalPosts,
    AVG(ViewCount) AS AvgViewCount,
    AVG(Score) AS AvgScore,
    SUM(CommentCount) AS TotalComments,
    SUM(VoteCount) AS TotalVotes,
    AVG(BadgeCount) AS AvgBadgeCount
FROM PostStats
WHERE PostTypeId IN (1, 2) -- Only considering Questions and Answers for benchmarking
AND CreationDate >= NOW() - INTERVAL '1 year'; -- Posts created in the last year
