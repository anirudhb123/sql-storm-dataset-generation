WITH UserBadges AS (
    SELECT UserId, 
           COUNT(*) AS BadgeCount, 
           MAX(Date) AS LastBadgeDate
    FROM Badges
    GROUP BY UserId
),
RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.ViewCount, 
           p.CreationDate, 
           ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year' 
      AND p.ViewCount > 100
),
ClosedPosts AS (
    SELECT ph.PostId AS ClosedPostId,
           ph.UserId AS CloserUserId,
           MAX(ph.CreationDate) AS ClosureDate
    FROM PostHistory ph 
    WHERE ph.PostHistoryTypeId = 10 -- Posts Closed
    GROUP BY ph.PostId, ph.UserId
),
PostComments AS (
    SELECT pc.PostId, 
           COUNT(pc.Id) AS CommentCount
    FROM Comments pc 
    GROUP BY pc.PostId
),
SubQueryVoting AS (
    SELECT v.PostId, 
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
)
SELECT p.Id AS PostId,
       p.Title,
       p.CreationDate,
       COALESCE(pb.BadgeCount, 0) AS UserBadgeCount,
       COALESCE(pc.CommentCount, 0) AS TotalComments,
       COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0) AS NetVotes,
       CASE WHEN cp.ClosedPostId IS NOT NULL THEN 'Closed' ELSE 'Open' END AS PostStatus,
       (SELECT STRING_AGG(Tags.TagName, ', ') 
        FROM Tags 
        WHERE Tags.Id IN (SELECT UNNEST(string_to_array(p.Tags, '>'))::INT)) AS RelatedTags
FROM RankedPosts p
LEFT JOIN UserBadges pb ON pb.UserId = p.OwnerUserId
LEFT JOIN PostComments pc ON pc.PostId = p.Id
LEFT JOIN SubQueryVoting v ON v.PostId = p.Id
LEFT JOIN ClosedPosts cp ON cp.ClosedPostId = p.Id
WHERE (p.Rank <= 10 OR p.Rank IS NULL)
  AND p.ViewCount IS NOT NULL
  AND (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = p.Id) > 0
ORDER BY p.ViewCount DESC, COALESCE(pb.BadgeCount, 0) DESC;

This SQL query provides a comprehensive performance benchmark by using multiple advanced SQL constructs:

- Common Table Expressions (CTEs) for structured data manipulation (`UserBadges`, `RankedPosts`, `ClosedPosts`, `PostComments`, and `SubQueryVoting`).
- A main selection that joins these constructs, leveraging both outer joins and conditional aggregation.
- Incorporates window functions for ranking posts based on view count.
- Utilizes COALESCE for handling NULL values and string aggregation for tags.
- Employs intricate predicates to filter and extract specific data points from the numerous tables in the schema.
- Includes the logic for determining post status (closed or open) and the handling of user badges associated with each post's owner.
