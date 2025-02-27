WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
), RankedPosts AS (
    SELECT p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 AND p.Score > 5
), RecentVotes AS (
    SELECT v.PostId, COUNT(*) AS VoteCount
    FROM Votes v
    WHERE v.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY v.PostId
), PostsWithVotes AS (
    SELECT rp.Id, rp.Title, rp.OwnerUserId, rp.CreationDate, rp.Score, 
           COALESCE(rv.VoteCount, 0) AS VoteCount, ub.BadgeCount
    FROM RankedPosts rp
    LEFT JOIN RecentVotes rv ON rp.Id = rv.PostId
    LEFT JOIN UserBadges ub ON rp.OwnerUserId = ub.UserId
)
SELECT pwv.Title, pwv.Score, pwv.VoteCount, ub.Name AS BadgeName, pwv.CreationDate,
       (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pwv.Id) AS CommentCount,
       CASE WHEN pwv.BadgeCount > 0 THEN 'Yes' ELSE 'No' END AS HasBadges,
       STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM PostsWithVotes pwv
LEFT JOIN PostTags pt ON pwv.Id = pt.PostId
LEFT JOIN Tags t ON pt.TagId = t.Id
WHERE pwv.PostRank = 1
GROUP BY pwv.Id, pwv.Title, pwv.Score, pwv.VoteCount, ub.Name, pwv.CreationDate, pwv.BadgeCount
ORDER BY pwv.Score DESC, pwv.CreationDate DESC
LIMIT 10;
