WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ParentId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Only questions as root posts

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate, 
        p.ParentId,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
UserVoteCounts AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM Votes v
    INNER JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.UserId
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpvoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownvoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        COUNT(DISTINCT pl.Id) AS LinkCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  -- Upvotes and Downvotes
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    GROUP BY p.Id
)
SELECT 
    rph.PostId,
    rph.Title,
    rph.CreationDate,
    COALESCE(pm.UpvoteCount, 0) AS TotalUpvotes,
    COALESCE(pm.DownvoteCount, 0) AS TotalDownvotes,
    pm.CommentCount,
    pm.HistoryCount,
    pm.LinkCount,
    CASE 
        WHEN rph.Level = 1 THEN 'Top-Level Question'
        ELSE 'Sub-thread'
    END AS PostTypeDescription,
    ROW_NUMBER() OVER (PARTITION BY rph.Level ORDER BY pm.UpvoteCount DESC) AS RankInLevel
FROM RecursivePostHierarchy rph
LEFT JOIN PostMetrics pm ON rph.PostId = pm.PostId
ORDER BY rph.CreationDate DESC
OPTION (MAXRECURSION 50);
