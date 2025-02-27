WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.UserDisplayName,
        1 AS Level
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened posts
    UNION ALL
    SELECT 
        ph.Id,
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.UserDisplayName,
        Level + 1
    FROM 
        PostHistory ph
    INNER JOIN 
        RecursivePostHistory rph ON ph.PostId = rph.PostId AND ph.CreationDate > rph.CreationDate
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS PostOwner,
    COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS Upvotes,
    COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS Downvotes,
    SUM(CASE WHEN ph.Comment IS NOT NULL THEN 1 ELSE 0 END) AS EditCount,
    STRING_AGG(DISTINCT b.Name, ', ') AS Badges,
    MAX(rph.Level) AS MaxEditLevel,
    MAX(rph.CreationDate) AS LastEditDate
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    RecursivePostHistory rph ON p.Id = rph.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' 
GROUP BY 
    p.Id, u.DisplayName
HAVING 
    SUM(CASE WHEN v.VoteTypeId IN (4, 10) THEN 1 ELSE 0 END) = 0 -- Exclude posts with spam or deleted votes
ORDER BY 
    Upvotes DESC, 
    LastEditDate DESC
LIMIT 50;
