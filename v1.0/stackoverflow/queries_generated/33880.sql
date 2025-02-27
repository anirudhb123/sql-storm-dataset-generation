WITH RecursiveTagCTE AS (
    SELECT Id, TagName, Count, IsModeratorOnly, 1 AS Depth
    FROM Tags
    WHERE IsModeratorOnly = 1
    
    UNION ALL
    
    SELECT t.Id, t.TagName, t.Count, t.IsModeratorOnly, rt.Depth + 1
    FROM Tags t
    JOIN RecursiveTagCTE rt ON rt.Id = t.ExcerptPostId
    WHERE t.IsModeratorOnly = 1
),
PostWithBadgeInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(b.Id) AS BadgeCount,
        SUM(b.Class) AS BadgeSum
    FROM Posts p
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY p.Id
),
VoteStatistics AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)

SELECT 
    pt.Id AS PostTypeId,
    pt.Name AS PostType,
    pw.PostId,
    pw.Title,
    pw.CreationDate,
    pw.BadgeCount,
    pw.BadgeSum,
    COALESCE(vs.UpVotes, 0) AS UpVoteCount,
    COALESCE(vs.DownVotes, 0) AS DownVoteCount,
    CASE 
        WHEN cp.LastCloseDate IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    t.TagName AS ModeratorTagName,
    t.Depth AS TagDepth
FROM PostTypes pt
JOIN Posts pw ON pt.Id = pw.PostTypeId
LEFT JOIN PostWithBadgeInfo pw ON pw.PostId = pw.Id
LEFT JOIN VoteStatistics vs ON pw.PostId = vs.PostId
LEFT JOIN ClosedPosts cp ON pw.PostId = cp.PostId
LEFT JOIN RecursiveTagCTE t ON pw.Id = t.ExcerptPostId OR pw.Id = t.WikiPostId
WHERE pw.Score > (SELECT AVG(Score) FROM Posts) -- Filter on average score
AND (pw.CreationDate < NOW() - INTERVAL '1 week' OR pw.ViewCount > 100)
ORDER BY pw.CreationDate DESC, BadgeCount DESC
LIMIT 100;
