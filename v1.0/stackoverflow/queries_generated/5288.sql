WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year' 
      AND p.PostTypeId = 1 -- Only questions
    GROUP BY p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        r.CommentCount,
        r.VoteCount
    FROM Users u
    JOIN RankedPosts r ON u.Id = r.PostRank
    WHERE r.PostRank <= 5 -- Top 5 posts per user
)
SELECT 
    ur.UserId, 
    ur.DisplayName, 
    ur.Reputation,
    ARRAY_AGG(ROW(ur.PostId, ur.Title, ur.CreationDate, ur.Score, ur.ViewCount, ur.CommentCount, ur.VoteCount)) AS TopPosts
FROM UserReputation ur
GROUP BY ur.UserId, ur.DisplayName, ur.Reputation
ORDER BY ur.Reputation DESC
LIMIT 10;
