WITH RecursivePostHistory AS (
    SELECT ph.PostId, 
           ph.CreationDate,
           ph.UserId,
           ph.PostHistoryTypeId,
           1 AS Depth
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11)  -- Only interested in Close and Reopen actions
    
    UNION ALL
    
    SELECT ph.PostId, 
           ph.CreationDate,
           ph.UserId,
           ph.PostHistoryTypeId,
           Depth + 1
    FROM PostHistory ph
    INNER JOIN RecursivePostHistory rph ON ph.PostId = rph.PostId 
    WHERE ph.CreationDate > rph.CreationDate  -- Get subsequent history entries
)

SELECT p.Id AS PostId,
       p.Title,
       p.Score,
       COUNT(DISTINCT c.Id) AS CommentCount,
       COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
       COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
       COUNT(DISTINCT b.Id) AS BadgeCount,
       ph.LastAction,
       LAST_VALUE(ph.PostHistoryTypeId) OVER (PARTITION BY p.Id ORDER BY ph.CreationDate ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LastHistoryType,
       STRING_AGG(t.TagName, ', ') AS Tags
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
LEFT JOIN (
    SELECT p.Id, 
           'Closed' AS LastAction
    FROM RecursivePostHistory rph
    INNER JOIN Posts p ON rph.PostId = p.Id
    WHERE rph.PostHistoryTypeId = 10 -- Closed posts
    UNION
    SELECT p.Id, 
           'Reopened' AS LastAction
    FROM RecursivePostHistory rph
    INNER JOIN Posts p ON rph.PostId = p.Id
    WHERE rph.PostHistoryTypeId = 11 -- Reopened posts
) ph ON p.Id = ph.Id
LEFT JOIN LATERAL (
    SELECT STRING_AGG(t.TagName, ', ') AS TagName
    FROM Tags t 
    WHERE t.Id IN (SELECT unnest(string_to_array(p.Tags, ','))::int)  -- Assuming Tags is a comma-separated string of Tag IDs
) t ON true
WHERE p.CreationDate > NOW() - INTERVAL '1 year'  -- Filter for posts from the last year
GROUP BY p.Id, p.Title, p.Score, ph.LastAction
ORDER BY p.Score DESC, CommentCount DESC;
