WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.PostTypeId, 
        p.OwnerUserId, 
        0 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id, 
        p.Title, 
        p.PostTypeId, 
        p.OwnerUserId, 
        r.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserVoteCounts AS (
    SELECT 
        v.UserId, 
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.UserId
),
PostPerformance AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.ViewCount,
        COALESCE(ph.AnswerCount, 0) AS AnswerCount,
        COALESCE(ph.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS Rank,
        ph.OwnerUserId
    FROM Posts p
    LEFT JOIN (
        SELECT 
            ParentId AS PostId, 
            COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS AnswerCount,
            COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS CommentCount
        FROM Posts
        GROUP BY ParentId
    ) ph ON p.Id = ph.PostId
)
SELECT 
    u.DisplayName,
    SUM(uvc.UpVotes) AS TotalUpVotes,
    SUM(ubvc.DownVotes) AS TotalDownVotes,
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.AnswerCount,
    pp.CommentCount,
    pp.Rank
FROM UserVoteCounts uvc
JOIN Users u ON uvc.UserId = u.Id
JOIN PostPerformance pp ON pp.OwnerUserId = u.Id
WHERE pp.Rank <= 10 
GROUP BY u.DisplayName, pp.PostId, pp.Title, pp.ViewCount, pp.AnswerCount, pp.CommentCount, pp.Rank
ORDER BY TotalUpVotes DESC;

-- This query performs the following functions:
-- 1. Recursive Common Table Expression (CTE) to build a post hierarchy.
-- 2. Counting upvotes and downvotes per user using a UserVoteCounts CTE.
-- 3. Combining post performance metrics such as view count, answer count, and comment count with window functions for ranking.
-- 4. Final selection of the top ten posts based on view count along with user vote totals.
