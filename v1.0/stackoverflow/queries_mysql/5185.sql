
WITH UserVoteCounts AS (
    SELECT 
        UserId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes
    GROUP BY UserId
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(v.UpVotes, 0) AS TotalUpVotes,
        COALESCE(v.DownVotes, 0) AS TotalDownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Posts p
    LEFT JOIN UserVoteCounts v ON p.OwnerUserId = v.UserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate > DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
    GROUP BY p.Id, p.Title, p.ViewCount, p.Score, v.UpVotes, v.DownVotes
),
RankedPosts AS (
    SELECT 
        pm.*, 
        @row_number := @row_number + 1 AS Rank
    FROM PostMetrics pm, (SELECT @row_number := 0) AS r
    ORDER BY pm.Score DESC, pm.ViewCount DESC
)
SELECT 
    rp.Rank, 
    rp.Title, 
    rp.PostId, 
    rp.ViewCount, 
    rp.Score, 
    rp.TotalUpVotes, 
    rp.TotalDownVotes, 
    rp.CommentCount, 
    rp.BadgeCount
FROM RankedPosts rp
WHERE rp.Rank <= 100
ORDER BY rp.Rank;
