WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.ParentId, 
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL  -- Start from top-level posts
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
PostVoteDetails AS (
    SELECT 
        post.Id AS PostId,
        post.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 6 THEN 1 ELSE 0 END), 0) AS CloseVotes
    FROM 
        Posts post
    LEFT JOIN 
        Votes v ON post.Id = v.PostId
    GROUP BY 
        post.Id, post.Title
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5) THEN 1 END) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    ph.LastEditDate,
    pd.UpVotes,
    pd.DownVotes,
    pd.CloseVotes,
    COALESCE(NULLIF((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0), 1) AS CommentCount,
    t.TagName,
    user.DisplayName AS LastEditorDisplayName,
    CASE 
        WHEN ph.LastEditDate IS NULL THEN 'No edits'
        ELSE 'Edited'
    END AS EditStatus,
    CASE 
        WHEN p.Score IS NULL THEN 0
        ELSE p.Score
    END AS AdjustedScore,
    RANK() OVER (ORDER BY p.CreationDate DESC) AS CreationRank
FROM 
    Posts p
LEFT JOIN 
    PostVoteDetails pd ON p.Id = pd.PostId
LEFT JOIN 
    PostHistoryAnalysis ph ON p.Id = ph.PostId
LEFT JOIN 
    Users user ON p.LastEditorUserId = user.Id
LEFT JOIN 
    Tags t ON p.Tags LIKE '%' || t.TagName || '%'
WHERE 
    p.Score > 0 
    OR (pd.UpVotes - pd.DownVotes) > 5
ORDER BY 
    CreationRank,
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
