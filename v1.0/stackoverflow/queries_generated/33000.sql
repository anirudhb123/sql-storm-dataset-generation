WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text,
        1 AS Level
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Posts that were closed or reopened.

    UNION ALL

    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text,
        Level + 1
    FROM 
        PostHistory ph
    INNER JOIN RecursivePostHistory rph ON ph.PostId = rph.PostId 
    WHERE 
        ph.CreationDate < rph.CreationDate  -- Ensuring to keep only earlier histories.
)

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    AVG(u.Reputation) AS AvgUserReputation,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    CASE 
        WHEN MAX(rph.PostHistoryTypeId) = 10 THEN 'Closed'
        WHEN MAX(rph.PostHistoryTypeId) = 11 THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Tags t ON p.Tags::text LIKE '%' || t.TagName || '%'
LEFT JOIN 
    RecursivePostHistory rph ON p.Id = rph.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Posts created in the last year
GROUP BY 
    p.Id, u.DisplayName
HAVING 
    AVG(u.Reputation) > 100  -- Only include posts where the average user reputation is greater than 100
ORDER BY 
    COUNT(DISTINCT v.Id) DESC,  -- Order by vote count
    p.CreationDate DESC;  -- Then by creation date

