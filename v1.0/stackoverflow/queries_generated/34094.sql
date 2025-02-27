WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostDetails AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    GROUP BY 
        p.Id
)
SELECT 
    pd.Title,
    pd.ViewCount,
    pd.CreationDate,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    COALESCE(phd.LastEditDate, 'Never Edited') AS LastEditDate,
    phd.HistoryTypes,
    CASE 
        WHEN pd.ViewCount > 1000 THEN 'Popular'
        ELSE 'Regular'
    END AS Popularity,
    rph.Level AS PostLevel
FROM 
    PostDetails pd
LEFT JOIN 
    PostHistoryDetails phd ON pd.Id = phd.PostId
LEFT JOIN 
    RecursivePostHierarchy rph ON pd.Id = rph.Id
WHERE 
    pd.CommentCount >= 5
ORDER BY 
    pd.UpVotes DESC,
    pd.ViewCount DESC,
    pd.CreationDate DESC;
