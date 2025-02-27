WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        0 AS Level,
        Title,
        CreationDate,
        OwnerUserId
    FROM 
        Posts
    WHERE 
        ParentId IS NULL -- Start with top-level posts
    UNION ALL
    SELECT 
        p.Id,
        p.ParentId,
        Level + 1,
        p.Title,
        p.CreationDate,
        p.OwnerUserId
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserVoteSummary AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 8 THEN v.BountyAmount ELSE 0 END) AS TotalBountyAmount
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostMetaData AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        COALESCE(ph.AvgViewCount, 0) AS AvgViewCount,
        COALESCE(u.Reputation, 0) AS OwnerReputation,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            AVG(ViewCount) AS AvgViewCount
        FROM 
            Posts
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN UserVoteSummary vs ON p.OwnerUserId = vs.UserId
),
PostHistoryActivity AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) -- Only title and body edits
    GROUP BY 
        ph.PostId
)
SELECT 
    pm.Id AS PostId,
    pm.Title,
    pm.CreationDate,
    pm.LastActivityDate,
    pm.AvgViewCount,
    pm.OwnerReputation,
    pm.UpVotes,
    pm.DownVotes,
    COALESCE(pha.EditCount, 0) AS TotalEdits,
    MAX(pha.LastEditDate) AS MostRecentEditDate,
    rph.Level AS PostLevel,
    rph.OwnerUserId AS HierarchyOwnerUserId
FROM 
    PostMetaData pm
LEFT JOIN 
    PostHistoryActivity pha ON pm.Id = pha.PostId
LEFT JOIN 
    RecursivePostHierarchy rph ON pm.Id = rph.Id
WHERE 
    pm.OwnerReputation > 1000 -- Filter on reputation
ORDER BY 
    pm.LastActivityDate DESC,
    pm.AvgViewCount DESC
LIMIT 100;
