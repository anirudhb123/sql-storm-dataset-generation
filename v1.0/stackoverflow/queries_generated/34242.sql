WITH RecursivePostPaths AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL -- Start with top-level posts

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostPaths r ON p.ParentId = r.PostId -- Traverse child posts
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(bw.BadgeCount, 0) AS BadgeCount,
        (COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0)) AS VoteBalance,
        r.Level
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount
        FROM Badges
        GROUP BY UserId
    ) bw ON p.OwnerUserId = bw.UserId
    LEFT JOIN RecursivePostPaths rp ON p.Id = rp.PostId
),
TopPosts AS (
    SELECT 
        ps.*,
        ROW_NUMBER() OVER (PARTITION BY ps.Level ORDER BY ps.VoteBalance DESC) AS RN
    FROM PostStatistics ps
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    tp.BadgeCount,
    tp.VoteBalance,
    CASE 
        WHEN tp.RN <= 10 THEN 'Top 10' 
        ELSE 'Lower'
    END AS Ranking
FROM TopPosts tp
WHERE tp.RN <= 10 OR Ranking = 'Lower' 
ORDER BY tp.Level, tp.VoteBalance DESC;

