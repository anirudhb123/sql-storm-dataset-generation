
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        @row_number := IF(@current_user = p.OwnerUserId, @row_number + 1, 1) AS OwnerRank,
        @current_user := p.OwnerUserId
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId,
    (SELECT @row_number := 0, @current_user := NULL) AS vars
    WHERE p.CreationDate > '2024-10-01 12:34:56' - INTERVAL 30 DAY
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COALESCE(b.Name, 'No Badge') AS BadgeName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.Views, u.UpVotes, u.DownVotes, b.Name
)
SELECT 
    up.DisplayName,
    up.Reputation,
    up.Views,
    up.PostsCount,
    up.TotalScore,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount
FROM UserStatistics up
JOIN RecentPosts rp ON up.UserId = rp.OwnerUserId
WHERE up.Reputation > 1000
  AND rp.CommentCount > 5
  AND EXISTS (
      SELECT 1 FROM Votes v 
      WHERE v.PostId = rp.PostId 
        AND v.VoteTypeId = 2  
        AND v.CreationDate > '2024-10-01 12:34:56' - INTERVAL 1 WEEK
  )
ORDER BY up.Reputation DESC, rp.Score DESC
LIMIT 50;
