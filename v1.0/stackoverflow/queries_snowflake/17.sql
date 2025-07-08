
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(c.Id), 0) AS TotalComments
    FROM Posts p
    LEFT JOIN Votes v ON v.PostId = p.Id
    LEFT JOIN Comments c ON c.PostId = p.Id
    WHERE p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56'::timestamp)
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Score,
        pd.ViewCount,
        pd.AnswerCount,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        RANK() OVER (ORDER BY pd.Score DESC, pd.ViewCount DESC) AS PostRank
    FROM PostDetail pd
    WHERE pd.ViewCount > 50
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
LEFT JOIN TopPosts tp ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId LIMIT 1)
WHERE ur.ReputationRank <= 10
ORDER BY ur.Reputation DESC, tp.Score DESC;
