WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId,
        Title,
        ParentId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVotes AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId IN (6, 10, 11) THEN 1 END) AS CloseVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
RecentPostEdits AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate,
        ph.UserId,
        ph.Text AS EditComment
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON ph.PostId = p.Id 
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days' 
        AND ph.PostHistoryTypeId in (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
),
ActiveWikis AS (
    SELECT 
        Id,
        Title,
        Tags,
        (EXTRACT(EPOCH FROM LastActivityDate) - EXTRACT(EPOCH FROM CreationDate)) / 86400 AS DaysActive
    FROM 
        Posts
    WHERE 
        PostTypeId IN (3, 4, 5) -- Wiki, TagWiki, TagWikiExcerpt
    HAVING 
        COUNT(*) > 0
)
SELECT 
    r.PostId,
    r.Title,
    COALESCE(pv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pv.DownVotes, 0) AS TotalDownVotes,
    COALESCE(pv.CloseVotes, 0) AS TotalCloseVotes,
    CASE WHEN ph.UserId IS NOT NULL THEN 'Recently Edited' ELSE 'Not Edited' END AS EditStatus,
    COALESCE(recent.EditsCount, 0) AS RecentEditsCount,
    COALESCE(a.DaysActive, 0) AS DaysActive
FROM 
    RecursivePostHierarchy r
LEFT JOIN 
    PostVotes pv ON r.PostId = pv.PostId
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS EditsCount 
     FROM 
         RecentPostEdits 
     GROUP BY 
         PostId) recent ON r.PostId = recent.PostId
LEFT JOIN 
    ActiveWikis a ON r.PostId = a.Id
WHERE 
    r.Level = 0
ORDER BY 
    TotalUpVotes DESC, 
    r.Title;
