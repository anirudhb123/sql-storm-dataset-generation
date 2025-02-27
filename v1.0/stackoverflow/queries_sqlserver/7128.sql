
WITH RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserReputation AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation, u.Views, u.UpVotes, u.DownVotes,
           ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    WHERE u.Reputation > 0
),
TopPosts AS (
    SELECT rp.*, ur.DisplayName AS OwnerDisplayName, ur.Reputation AS OwnerReputation
    FROM RecentPosts rp
    JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE rp.Score > 5 AND rp.CommentCount > 2
    ORDER BY rp.Score DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.CommentCount, 
       tp.OwnerDisplayName, tp.OwnerReputation
FROM TopPosts tp
JOIN Posts p ON tp.Id = p.Id
LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
GROUP BY tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.CommentCount, 
         tp.OwnerDisplayName, tp.OwnerReputation
ORDER BY COUNT(v.Id) DESC, tp.Score DESC;
