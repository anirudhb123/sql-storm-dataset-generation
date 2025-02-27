WITH RecursiveBadges AS (
    SELECT b.Id, b.UserId, b.Name, b.Date, b.Class,
           ROW_NUMBER() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS BadgeRank
    FROM Badges b
),
RecentPosts AS (
    SELECT p.Id, p.Title, p.OwnerUserId, p.CreationDate,
           COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswer,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
RankedPosts AS (
    SELECT rp.*, 
           RANK() OVER (ORDER BY rp.CommentCount DESC, rp.UpVotes - rp.DownVotes DESC) AS PostRank
    FROM RecentPosts rp
),
UsersWithBadges AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           ub.Id AS BadgeId, 
           ub.Name AS BadgeName
    FROM Users u
    LEFT JOIN RecursiveBadges ub ON u.Id = ub.UserId
    WHERE ub.BadgeRank = 1
)
SELECT uwb.DisplayName,
       p.Id AS PostId,
       p.Title,
       p.CreationDate,
       (SELECT COUNT(*) 
        FROM PostHistory ph 
        WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 11)) AS CloseEventCount,
       COUNT(c.Id) AS TotalComments,
       CASE 
           WHEN p.AcceptedAnswer > 0 THEN (SELECT Title FROM Posts WHERE Id = p.AcceptedAnswer)
           ELSE 'No Accepted Answer'
       END AS AcceptedAnswerTitle,
       MAX(ub.BadgeName) AS MostRecentBadge
FROM RankedPosts p
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN UsersWithBadges uwb ON uwb.UserId = p.OwnerUserId
LEFT JOIN Badges ub ON ub.UserId = p.OwnerUserId
WHERE p.PostRank <= 10
GROUP BY uwb.DisplayName, p.Id, p.Title, p.CreationDate, p.AcceptedAnswer
ORDER BY p.CreationDate DESC;
