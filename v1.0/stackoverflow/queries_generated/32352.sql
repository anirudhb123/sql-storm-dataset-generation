WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Starting from Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostScoreSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUM(COALESCE(vt.Score, 0)) AS TotalScore,
        AVG(COALESCE(vt.Score, 0)) AS AverageScore
    FROM Posts p
    LEFT JOIN Votes vt ON p.Id = vt.PostId
    GROUP BY p.Id, p.Title
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate AS ClosedDate
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10 -- Closed posts
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ps.AverageScore, 0) AS AverageScore,
        COALESCE(SUM(cp.ClosedDate IS NOT NULL), 0) AS IsClosedPost,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN PostScoreSummary ps ON p.Id = ps.PostId
    LEFT JOIN ClosedPosts cp ON p.Id = cp.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, ps.TotalScore, ps.AverageScore
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    p.Title,
    ps.TotalScore,
    ps.AverageScore,
    ps.IsClosedPost,
    us.UpVotes,
    us.DownVotes,
    ps.CommentCount,
    COALESCE(ps.commentCount * 1.0 / NULLIF(us.TotalVotes, 0), 0) AS CommentToVoteRatio,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM Users u
JOIN Posts p ON u.Id = p.OwnerUserId
JOIN PostStats ps ON p.Id = ps.PostId
LEFT JOIN UserVoteStats us ON u.Id = us.UserId
LEFT JOIN LATERAL STRING_TO_ARRAY(p.Tags, ',') AS tag ON true -- Assuming Tags can be processed directly
LEFT JOIN Tags t ON t.TagName = TRIM(BOTH ' ' FROM tag)
WHERE ps.TotalScore > 0 OR ps.IsClosedPost = 1
GROUP BY u.Id, u.DisplayName, p.Title, ps.TotalScore, ps.AverageScore, ps.IsClosedPost, us.UpVotes, us.DownVotes, ps.CommentCount
ORDER BY TotalScore DESC, CommentCount DESC;
