WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.Comment,
        1 AS Level
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Only considering Close and Reopen events

    UNION ALL

    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.Comment,
        rp.Level + 1
    FROM PostHistory ph
    INNER JOIN RecursivePostHistory rp ON rp.PostId = ph.PostId
    WHERE ph.CreationDate < rp.CreationDate 
)
SELECT 
    p.Id AS PostId,
    p.Title,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,  -- Upvotes
    COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount, -- Downvotes
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    MAX(rp.CreationDate) AS LastCloseOrReopenDate,
    COUNT(DISTINCT CASE WHEN bp.Class = 1 THEN bp.Id END) AS GoldBadgeCount,
    COUNT(DISTINCT CASE WHEN bp.Class = 2 THEN bp.Id END) AS SilverBadgeCount,
    COUNT(DISTINCT CASE WHEN bp.Class = 3 THEN bp.Id END) AS BronzeBadgeCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
LEFT JOIN 
    Badges bp ON bp.UserId = p.OwnerUserId
LEFT JOIN 
    RecursivePostHistory rp ON rp.PostId = p.Id
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])  -- Assuming tags stored as comma-separated IDs
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for posts created in the last year
GROUP BY 
    p.Id, p.Title
ORDER BY 
    p.Title;
