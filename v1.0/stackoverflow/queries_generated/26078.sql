WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Body,
           p.Tags,
           p.CreationDate,
           p.ViewCount,
           p.Score,
           ROW_NUMBER() OVER (PARTITION BY substring(p.Tags, 2, length(Tags) - 2) ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1 
    AND p.CreationDate >= NOW() - INTERVAL '1 year'
), TopPosts AS (
    SELECT PostId,
           Title,
           Body,
           Tags,
           ViewCount,
           Score
    FROM RankedPosts
    WHERE Rank <= 5
), UserScores AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
)
SELECT tp.PostId,
       tp.Title,
       tp.Body,
       tp.Tags,
       tp.ViewCount,
       tp.Score,
       us.DisplayName,
       us.UpVotes,
       us.DownVotes
FROM TopPosts tp
JOIN Users u ON tp.PostId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = tp.PostId)
JOIN UserScores us ON u.Id = us.UserId
ORDER BY tp.Score DESC, tp.ViewCount DESC;
