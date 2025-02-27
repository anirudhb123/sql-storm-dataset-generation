WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) AS CommentCount 
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.ViewCount, p.CreationDate, p.PostTypeId
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(*) AS VoteCount
    FROM Votes v
    WHERE v.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY v.PostId, v.VoteTypeId
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CommentCount,
        COALESCE(SUM(rv.VoteCount) FILTER (WHERE rv.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(rv.VoteCount) FILTER (WHERE rv.VoteTypeId = 3), 0) AS DownVotes
    FROM RankedPosts rp
    LEFT JOIN RecentVotes rv ON rp.PostId = rv.PostId
    GROUP BY rp.PostId, rp.Title, rp.ViewCount, rp.CommentCount
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.ViewCount,
    pm.CommentCount,
    pm.UpVotes,
    pm.DownVotes,
    CASE 
        WHEN pm.UpVotes - pm.DownVotes > 0 THEN 'Positive'
        WHEN pm.UpVotes - pm.DownVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    CASE 
        WHEN pm.CommentCount > 5 THEN 'Highly Discussed'
        WHEN pm.CommentCount BETWEEN 1 AND 5 THEN 'Moderately Discussed'
        ELSE 'Not Discussed'
    END AS DiscussionLevel
FROM PostMetrics pm
WHERE pm.ViewCount > 50
  AND (pm.UpVotes + pm.DownVotes) > 0
  AND pm.CommentCount IS NOT NULL
ORDER BY pm.ViewCount DESC, pm.UpVotes DESC
LIMIT 10;

-- Additional insights about post history related to recent changes
SELECT 
    ph.PostId,
    COUNT(*) AS HistoryCount,
    STRING_AGG(ph.Comment, '; ') AS Comments
FROM PostHistory ph
WHERE ph.CreationDate >= NOW() - INTERVAL '1 month'
GROUP BY ph.PostId
HAVING COUNT(*) > 1
ORDER BY HistoryCount DESC;

The above SQL query utilizes various constructs such as Common Table Expressions (CTEs) for ranking posts, filtering votes, and aggregating post metrics. It also incorporates outer joins, window functions, aggregate functions, and case statements to derive additional insights while addressing complex predicates to filter and classify the posts based on view count and voting activity. The second part of the query provides information on the history of posts with relevant comments for those that have undergone recent updates.
