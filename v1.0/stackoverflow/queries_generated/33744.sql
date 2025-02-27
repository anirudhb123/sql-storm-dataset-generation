WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        1 AS Level
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closed and Reopened posts
    UNION ALL
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        Level + 1
    FROM 
        PostHistory ph
    INNER JOIN 
        RecursivePostHistory rph ON ph.PostId = rph.PostId
    WHERE 
        rph.Level < 5  -- Limit recursion depth for performance
)

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    MAX(rph.CreationDate) AS LastPostAction,
    MAX(rph.Comment) AS LastActionComment
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    Tags t ON t.Id = ANY (STRING_TO_ARRAY(p.Tags, '><')::int[])
LEFT JOIN 
    RecursivePostHistory rph ON rph.PostId = p.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for posts created in the last year
    AND (p.Score > 5 OR p.ViewCount > 100)  -- Performance criteria based on Score and ViewCount
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName
ORDER BY 
    PostId DESC;
