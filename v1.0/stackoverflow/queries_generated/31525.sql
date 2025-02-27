WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId, 
        ph.Id AS HistoryId,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        0 AS Level
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    UNION ALL
    SELECT 
        p.Id AS PostId, 
        ph.Id AS HistoryId,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        Level + 1
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        RecursivePostHistory rph ON rph.PostId = p.Id 
    WHERE 
        rph.Level < 5  -- Limiting depth for recursion
)

SELECT 
    u.DisplayName AS UserDisplayName,
    MAX(p.CreationDate) AS LastPostDate,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Id END) AS TotalCloseVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyAwarded,
    COUNT(DISTINCT CASE WHEN ph.UserId IS NOT NULL THEN ph.Id END) AS HistoryWithUser,
    AVG(u.Reputation) AS AvgReputation,
    MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastCloseDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 12  -- Considering spam votes
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
WHERE 
    u.Reputation > 100  -- Filtering users with reputation greater than 100 
    AND (ph.PostHistoryTypeId IS NULL OR ph.PostHistoryTypeId NOT IN (12, 10))  -- Not counting certain history types
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5  -- At least 5 posts
ORDER BY 
    LastPostDate DESC;

