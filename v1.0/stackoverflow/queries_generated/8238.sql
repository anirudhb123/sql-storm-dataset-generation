WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.Score, 
           p.ViewCount, 
           COUNT(c.Id) AS CommentCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
), TotalVotes AS (
    SELECT p.Id, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
), UserBadgeCount AS (
    SELECT u.Id AS UserId, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT up.OwnerDisplayName, 
       rp.Title, 
       rp.Score, 
       rp.CommentCount, 
       tv.UpVotes, 
       tv.DownVotes, 
       ubc.BadgeCount,
       rp.UserPostRank
FROM RankedPosts rp
JOIN Posts p ON rp.Id = p.Id
JOIN Users up ON p.OwnerUserId = up.Id
JOIN TotalVotes tv ON rp.Id = tv.Id
JOIN UserBadgeCount ubc ON up.Id = ubc.UserId
WHERE rp.UserPostRank <= 5
ORDER BY up.Reputation DESC, rp.Score DESC;
