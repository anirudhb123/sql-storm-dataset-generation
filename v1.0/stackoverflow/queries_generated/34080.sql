WITH RECURSIVE PostHierarchy AS (
    SELECT p.Id AS PostId, p.Title, p.ParentId, 
           1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Start with questions
    
    UNION ALL
    
    SELECT p.Id, p.Title, p.ParentId, 
           ph.Level + 1
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.PostId
),
UserStatistics AS (
    SELECT u.Id AS UserId,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
           COUNT(DISTINCT b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
ClosedPosts AS (
    SELECT ph.PostId, ph.Title, ph.Level, 
           COUNT(h.Id) AS CloseCount
    FROM PostHierarchy ph
    LEFT JOIN PostHistory h ON ph.PostId = h.PostId AND h.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY ph.PostId, ph.Title, ph.Level
),
PostVoteSummary AS (
    SELECT p.OwnerUserId, 
           COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
           COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
           COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId IN (1, 2)  -- Questions and Answers
    GROUP BY p.OwnerUserId
)
SELECT u.Id AS UserId, 
       u.DisplayName,
       us.TotalUpVotes, 
       us.TotalDownVotes,
       us.TotalBadges,
       COALESCE(ps.Upvotes, 0) AS UserPostUpvotes,
       COALESCE(ps.Downvotes, 0) AS UserPostDownvotes,
       COALESCE(ps.CommentCount, 0) AS UserPostCommentCount,
       COALESCE(cp.CloseCount, 0) AS ClosedPostCount
FROM Users u
LEFT JOIN UserStatistics us ON u.Id = us.UserId
LEFT JOIN PostVoteSummary ps ON u.Id = ps.OwnerUserId
LEFT JOIN ClosedPosts cp ON u.Id IN (
    SELECT DISTINCT p.OwnerUserId 
    FROM Posts p 
    WHERE p.Id IN (SELECT PostId FROM ClosedPosts)
)
WHERE u.Reputation > 100 -- Only users with reputation greater than 100
ORDER BY u.Reputation DESC;
