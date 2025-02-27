
WITH UserReputation AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CASE 
            WHEN Reputation < 100 THEN 'Newbie'
            WHEN Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM Users
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY p.Id, p.Title, p.Score, p.CreationDate
),
TopPosts AS (
    SELECT 
        *,
        @rank := IF(@prev_score = Score, @rank + 1, 1) AS Rank,
        @prev_score := Score
    FROM PostStatistics, (SELECT @rank := 0, @prev_score := NULL) AS init
    WHERE Score > 10
    ORDER BY Score, CommentCount DESC
)
SELECT 
    ur.DisplayName,
    ur.ReputationLevel,
    tp.Title,
    tp.Score,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount
FROM UserReputation ur
JOIN Posts p ON ur.Id = p.OwnerUserId
JOIN TopPosts tp ON p.Id = tp.PostId
WHERE ur.ReputationLevel = 'Expert'
  AND tp.Rank <= 5
ORDER BY tp.CommentCount DESC, tp.Score DESC;
