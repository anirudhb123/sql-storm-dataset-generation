WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM RankedPosts rp
    WHERE rp.PostRank <= 10 -- Top 10 posts per user
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
    HAVING u.Reputation > 1000 -- Only users with high reputation
)
SELECT 
    up.DisplayName,
    COUNT(tp.PostId) AS TotalTopPosts,
    AVG(tp.Score) AS AvgScore,
    SUM(up.BadgeCount) AS TotalBadges
FROM UserReputation up
LEFT JOIN TopPosts tp ON up.UserId = tp.OwnerDisplayName
GROUP BY up.DisplayName
ORDER BY TotalTopPosts DESC, AvgScore DESC
LIMIT 10;
