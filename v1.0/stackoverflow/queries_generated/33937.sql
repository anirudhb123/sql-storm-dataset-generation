WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        0 AS Level,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Select only Questions
    
    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        rp.Level + 1,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Level,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    RecursivePosts rp
LEFT JOIN 
    Comments c ON rp.PostId = c.PostId
LEFT JOIN 
    Votes v ON rp.PostId = v.PostId
LEFT JOIN 
    (SELECT 
         DISTINCT unnest(string_to_array(Tags, '><')) AS TagName,
         PostId 
     FROM 
         Posts) t ON t.PostId = rp.PostId
GROUP BY 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Level
ORDER BY 
    rp.Level DESC, 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 100;

-- Additional benchmarking for closed posts and vote history
SELECT 
    ph.PostId,
    hist.Type AS PostHistoryType,
    COUNT(*) AS HistoryCount,
    STRING_AGG(DISTINCT CONCAT(u.DisplayName, ' (', u.Reputation, ')'), ', ') AS Editors
FROM 
    PostHistory ph
INNER JOIN 
    (SELECT 
         Id, 
         CASE 
             WHEN PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
             WHEN PostHistoryTypeId = 12 THEN 'Deleted'
             WHEN PostHistoryTypeId = 13 THEN 'Undeleted'
             ELSE 'Edited'
         END AS Type
     FROM 
         PostHistoryTypes) hist ON ph.PostHistoryTypeId = hist.Id
LEFT JOIN 
    Users u ON ph.UserId = u.Id
WHERE 
    ph.PostId IN (SELECT PostId FROM Posts WHERE ClosedDate IS NOT NULL)
GROUP BY 
    ph.PostId, hist.Type
ORDER BY 
    HistoryCount DESC
LIMIT 50;
