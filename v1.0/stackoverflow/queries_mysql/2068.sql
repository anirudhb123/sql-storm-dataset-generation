
WITH UserVoteCounts AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 END) AS TotalVotes,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes v
    GROUP BY v.UserId
), 
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        COALESCE(p.FavoriteCount, 0) AS FavoriteCount,
        @rank := @rank + 1 AS ViewRank
    FROM Posts p, (SELECT @rank := 0) r
    WHERE p.CreationDate >= '2023-10-01 12:34:56'
    ORDER BY p.ViewCount DESC
), 
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pht.Name ORDER BY pht.Name SEPARATOR ', ') AS ChangeTypes,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
), 
TopPosts AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.ViewCount,
        pm.AnswerCount,
        pm.CommentCount,
        pm.FavoriteCount,
        pha.LastChangeDate,
        pha.ChangeTypes,
        @rank2 := @rank2 + 1 AS Rank
    FROM PostMetrics pm, (SELECT @rank2 := 0) r2
    LEFT JOIN PostHistoryAggregates pha ON pm.PostId = pha.PostId
    ORDER BY pm.ViewCount DESC
)
SELECT 
    u.DisplayName,
    u.Reputation,
    tp.Title,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.FavoriteCount,
    COALESCE(uvc.TotalVotes, 0) AS UserVoteCount,
    COALESCE(uvc.UpVotes, 0) AS UserUpVotes,
    COALESCE(uvc.DownVotes, 0) AS UserDownVotes,
    tp.ChangeTypes,
    tp.LastChangeDate
FROM TopPosts tp
JOIN Users u ON u.Id IN (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN UserVoteCounts uvc ON uvc.UserId = u.Id
WHERE tp.Rank <= 10
ORDER BY tp.ViewCount DESC;
