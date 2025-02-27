WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only Questions
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY u.Id, u.Reputation
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ur.Reputation,
        ur.TotalBadges,
        ur.CommentCount
    FROM RankedPosts rp
    INNER JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE rp.UserPostRank <= 5 -- Top 5 posts per user
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        MAX(v.CreationDate) AS LastVoteDate
    FROM Votes v
    GROUP BY v.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.Reputation,
    tp.TotalBadges,
    COALESCE(rv.VoteCount, 0) AS VoteCount,
    rv.LastVoteDate,
    CASE 
        WHEN tp.Score > 100 THEN 'High Score'
        WHEN tp.Score BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM TopPosts tp
LEFT JOIN RecentVotes rv ON tp.PostId = rv.PostId
ORDER BY tp.Reputation DESC, tp.Score DESC;
