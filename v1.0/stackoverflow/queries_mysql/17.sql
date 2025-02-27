
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        @row_number := @row_number + 1 AS ReputationRank
    FROM Users u, (SELECT @row_number := 0) AS r
    ORDER BY u.Reputation DESC
),
PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS TotalComments
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Score,
        pd.ViewCount,
        pd.AnswerCount,
        pd.CommentCount,
        @post_rank := @post_rank + 1 AS PostRank
    FROM PostDetail pd, (SELECT @post_rank := 0) AS r
    WHERE pd.ViewCount > 50
    ORDER BY pd.Score DESC, pd.ViewCount DESC
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.ReputationRank,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes
FROM UserReputation ur
LEFT JOIN TopPosts tp ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
WHERE ur.ReputationRank <= 10
ORDER BY ur.Reputation DESC, tp.Score DESC;
