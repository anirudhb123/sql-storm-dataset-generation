WITH RecursiveParentPosts AS (
    -- Recursive CTE to find all parent posts of answers
    SELECT p.Id AS PostId, p.ParentId, p.Title, 1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 2  -- Answers
    UNION ALL
    SELECT p.Id AS PostId, p.ParentId, p.Title, rp.Level + 1
    FROM Posts p
    INNER JOIN RecursiveParentPosts rp ON p.Id = rp.ParentId
),
PostVoteSummary AS (
    -- Aggregate votes for each post
    SELECT
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId
),
HighVotePosts AS (
    -- Select posts with more than 10 UpVotes
    SELECT p.Id, p.Title, p.Score, p.OwnerUserId
    FROM Posts p
    JOIN PostVoteSummary pvs ON p.Id = pvs.PostId
    WHERE pvs.UpVotes > 10
),
LatestComment AS (
    -- Retrieve the latest comment for high vote posts
    SELECT c.PostId, c.Text, c.CreationDate
    FROM Comments c
    JOIN HighVotePosts h ON c.PostId = h.Id
    WHERE c.CreationDate = (SELECT MAX(CreationDate) FROM Comments WHERE PostId = h.Id)
),
UserReputation AS (
    -- A summary of user reputation based on posts and comments made
    SELECT u.Id AS UserId,
           SUM(COALESCE(p.Score, 0)) AS TotalPostScore,
           SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
           COUNT(DISTINCT p.Id) AS PostCount,
           COUNT(DISTINCT c.Id) AS CommentCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY u.Id
)
-- Final selection of relevant information
SELECT
    up.UserId,
    u.DisplayName,
    up.TotalPostScore,
    up.PostCount,
    up.TotalCommentScore,
    up.CommentCount,
    COALESCE(lc.Text, 'No comments available') AS LatestComment,
    COALESCE(lc.CreationDate, 'No comments available') AS CommentDate,
    rp.Title AS HighVotePostTitle,
    rp.Level AS ParentLevel
FROM UserReputation up
JOIN Users u ON up.UserId = u.Id
LEFT JOIN LatestComment lc ON lc.PostId IN (SELECT h.Id FROM HighVotePosts h)
LEFT JOIN RecursiveParentPosts rp ON rp.PostId IN (SELECT h.Id FROM HighVotePosts h)
WHERE up.TotalPostScore > 1000  -- Filter users with significant reputation
ORDER BY up.TotalPostScore DESC, up.CommentCount DESC;
