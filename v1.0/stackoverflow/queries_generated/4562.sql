WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
FilteredPosts AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        ur.Reputation,
        ROW_NUMBER() OVER (ORDER BY rp.ViewCount DESC) AS PostRank
    FROM RankedPosts rp
    JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE ur.Reputation > 100
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.Reputation,
    CASE 
        WHEN fp.Score > 10 THEN 'High Score'
        WHEN fp.Score BETWEEN 5 AND 10 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM FilteredPosts fp
WHERE fp.PostRank <= 10
ORDER BY fp.Reputation DESC, fp.ViewCount DESC;

-- Additional query to retrieve comments on those posts
SELECT 
    c.Id AS CommentId,
    c.PostId,
    c.Text,
    c.CreationDate,
    u.DisplayName AS Commenter
FROM Comments c
JOIN Posts p ON c.PostId = p.Id
JOIN Users u ON c.UserId = u.Id
WHERE p.Id IN (SELECT PostId FROM FilteredPosts)
ORDER BY c.CreationDate DESC;
