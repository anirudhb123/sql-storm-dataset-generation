WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        0 AS Level,
        p.CreationDate,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Start from root posts (which have no parent)
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        Level + 1,
        p.CreationDate,
        p.OwnerUserId
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
), 
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
SELECT 
    rph.PostId,
    rph.Title,
    rph.Level,
    rph.CreationDate,
    u.DisplayName AS Owner,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN rph.Level > 0 THEN 'Reply'
        ELSE 'Original Post'
    END AS PostHierarchyLevel,
    DENSE_RANK() OVER (PARTITION BY rph.Level ORDER BY rph.CreationDate DESC) AS RecentPostRank,
    pht.Name AS PostHistoryType,
    ph.CreationDate AS PostHistoryDate
FROM 
    RecursivePostHierarchy rph
LEFT JOIN 
    Users u ON rph.OwnerUserId = u.Id
LEFT JOIN 
    PostVotes pv ON rph.PostId = pv.PostId
LEFT JOIN 
    PostHistory ph ON rph.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    rph.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for posts created in the last year
    AND (pv.UpVotes > 20 OR pv.DownVotes > 10)  -- Only include posts with substantial votes
ORDER BY 
    rph.Level, rph.CreationDate DESC;
