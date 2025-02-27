
WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName AS OwnerDisplayName
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(DAY, 30, 0) AND p.PostTypeId = 1
),
PostStats AS (
    SELECT rp.Id, rp.Title, rp.OwnerDisplayName, rp.ViewCount, rp.Score, 
           COUNT(c.Id) AS CommentCount, 
           COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.UserId END) AS UpVoteCount,
           COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.UserId END) AS DownVoteCount
    FROM RecentPosts rp
    LEFT JOIN Comments c ON rp.Id = c.PostId
    LEFT JOIN Votes v ON rp.Id = v.PostId
    GROUP BY rp.Id, rp.Title, rp.OwnerDisplayName, rp.ViewCount, rp.Score
),
RankedPosts AS (
    SELECT ps.*, 
           RANK() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS RankScore,
           RANK() OVER (ORDER BY ps.CommentCount DESC) AS RankComments
    FROM PostStats ps
)
SELECT rp.Id, rp.Title, rp.OwnerDisplayName, rp.ViewCount, rp.Score, 
       rp.CommentCount, rp.UpVoteCount, rp.DownVoteCount, 
       rp.RankScore, rp.RankComments
FROM RankedPosts rp
WHERE rp.RankScore <= 10 OR rp.RankComments <= 10
ORDER BY rp.RankScore, rp.RankComments;
