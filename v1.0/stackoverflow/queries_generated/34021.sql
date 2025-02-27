WITH RecursivePosts AS (
    SELECT Id, PostTypeId, AcceptedAnswerId, ParentId, CreationDate,
           Title, Score, ViewCount, OwnerUserId,
           0 AS Level -- Base level
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT p.Id, p.PostTypeId, p.AcceptedAnswerId, p.ParentId, p.CreationDate,
           p.Title, p.Score, p.ViewCount, p.OwnerUserId,
           rp.Level + 1 -- Increment level for child posts
    FROM Posts p
    INNER JOIN RecursivePosts rp ON p.ParentId = rp.Id
),
UserVoteSummary AS (
    SELECT UserId, COUNT(*) AS TotalVotes, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    GROUP BY UserId
),
PostStats AS (
    SELECT p.Id, p.Title, p.OwnerUserId, p.Score, p.ViewCount,
           COALESCE(u.TotalVotes, 0) AS UserTotalVotes,
           COALESCE(u.UpVotes, 0) AS UserUpVotes,
           COALESCE(u.DownVotes, 0) AS UserDownVotes,
           COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN UserVoteSummary u ON p.OwnerUserId = u.UserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= '2022-01-01' -- Filter for posts created in 2022 onwards
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.Score, p.ViewCount, u.TotalVotes, u.UpVotes, u.DownVotes
),
TagUsage AS (
    SELECT t.TagName, COUNT(p.Id) AS PostCount
    FROM Tags t
    INNER JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
)
SELECT ps.Title, ps.Score, ps.ViewCount,
       (SELECT STRING_AGG(TagName, ', ') FROM TagUsage WHERE PostCount > 5) AS PopularTags,
       ps.UserTotalVotes, ps.UserUpVotes, ps.UserDownVotes, ps.CommentCount,
       ROW_NUMBER() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.Score DESC) AS RankByScore
FROM PostStats ps
WHERE ps.Score > 10 -- Only include posts with a significant score
  AND ps.CommentCount > 2 -- Only include posts with multiple comments
ORDER BY ps.Score DESC, ps.ViewCount DESC;
