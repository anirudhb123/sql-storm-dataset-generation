WITH RecursivePosts AS (
    SELECT p.Id, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           p.OwnerUserId, 
           p.AcceptedAnswerId, 
           1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1
    UNION ALL
    SELECT p.Id, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           p.OwnerUserId, 
           p.AcceptedAnswerId, 
           rp.Level + 1
    FROM Posts p
    INNER JOIN RecursivePosts rp ON p.ParentId = rp.Id
    WHERE p.PostTypeId = 2
), RecentPosts AS (
    SELECT rp.Id, 
           rp.Title, 
           rp.CreationDate, 
           rp.Score, 
           u.DisplayName AS OwnerName, 
           COUNT(c.Id) AS CommentCount,
           ROW_NUMBER() OVER (PARTITION BY rp.OwnerUserId ORDER BY rp.CreationDate DESC) AS OwnerPostRank
    FROM RecursivePosts rp
    LEFT JOIN Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN Comments c ON rp.Id = c.PostId
    WHERE EXISTS (
        SELECT 1 
        FROM Votes v
        WHERE v.PostId = rp.Id 
          AND v.VoteTypeId = 2 
          AND v.CreationDate >= NOW() - INTERVAL '30 days' 
    )
    GROUP BY rp.Id, rp.Title, rp.CreationDate, rp.Score, u.DisplayName
), FilteredPosts AS (
    SELECT *,
           CASE 
               WHEN CommentCount > 3 THEN 'Highly Discussed' 
               ELSE 'Less Discussed' 
           END AS DiscussionType
    FROM RecentPosts
    WHERE OwnerPostRank = 1
)
SELECT fp.Title,
       fp.CreationDate,
       fp.Score,
       fp.OwnerName,
       fp.DiscussionType,
       CASE 
           WHEN fp.Score IS NULL THEN 'No Score' 
           WHEN fp.Score > 0 THEN 'Positive Score' 
           ELSE 'Negative Score' 
       END AS ScoreStatus
FROM FilteredPosts fp
LEFT JOIN Badges b ON fp.OwnerUserId = b.UserId
WHERE b.Class = 1 
  AND (b.Date > fp.CreationDate OR b.Date IS NULL)
ORDER BY fp.CreationDate DESC
LIMIT 10
OFFSET 0;
