WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        1 AS Level
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened Posts
    UNION ALL
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        Level + 1
    FROM 
        PostHistory ph
    JOIN 
        RecursivePostHistory rph ON ph.PostId = rph.PostId AND ph.CreationDate > rph.CreationDate
)
SELECT 
    p.Title,
    u.DisplayName AS OwnerName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    MAX(rph.CreationDate) AS LastStatusChange,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    CASE 
        WHEN MAX(rph.PostHistoryTypeId) = 10 THEN 'Closed'
        WHEN MAX(rph.PostHistoryTypeId) = 11 THEN 'Reopened'
        ELSE 'Unknown'
    END AS CurrentStatus
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    RecursivePostHistory rph ON p.Id = rph.PostId
LEFT JOIN 
    LATERAL (SELECT * FROM Tags WHERE Id = ANY(string_to_array(p.Tags, ','::TEXT)::INT[])) t ON true
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for posts created in the last year
GROUP BY 
    p.Id, u.DisplayName
HAVING 
    COUNT(DISTINCT c.Id) > 0 -- Only including posts with comments
ORDER BY 
    UpVoteCount DESC, 
    CommentCount DESC
LIMIT 50;
