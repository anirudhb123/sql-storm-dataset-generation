WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Only interested in posts that were closed or reopened
    UNION ALL
    SELECT 
        pl.RelatedPostId,
        r.Title,
        r.CreationDate,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY r.Id ORDER BY ph.CreationDate DESC) 
    FROM 
        PostLinks pl
    JOIN 
        Posts r ON pl.PostId = r.Id
    JOIN 
        PostHistory ph ON r.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
        AND pl.LinkTypeId = 3 -- Only duplicates
)
SELECT 
    p.Title,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    AVG(u.Reputation) AS AvgReputation,
    MAX(ph.CreationDate) AS LastHistoryActionDate
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    RecursiveCTE r ON p.Id = r.PostId
WHERE 
    r.rn = 1
    AND r.PostHistoryTypeId = 10 -- Only closed posts initially
    AND p.CreationDate < NOW() -- Only consider posts created in the past
GROUP BY 
    p.Title
HAVING 
    COUNT(DISTINCT c.Id) > 5 -- Only include posts with more than 5 comments
ORDER BY 
    AvgReputation DESC, 
    LastHistoryActionDate DESC
FETCH FIRST 100 ROWS ONLY;

This query utilizes recursive common table expressions (CTEs) to traverse a hierarchy of posts linked by duplicates, evaluates various metrics on closed posts (including comment count, vote sums, and badge counts), applies multiple outer joins, and incorporates complex aggregation logic with conditions to filter down the results based on specific criteria.
