WITH RecursivePostHierarchy AS (
    SELECT 
        Id, 
        Title, 
        PostTypeId, 
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
        p.PostTypeId, 
        p.ParentId, 
        rph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),

UserVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 WHEN vt.Name = 'DownMod' THEN -1 ELSE 0 END) AS Score
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),

PostHistorySummary AS (
    SELECT
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    COALESCE(up.Score, 0) AS UserVoteScore,
    COALESCE(psz.EditCount, 0) AS TotalEdits,
    COALESCE(psz.LastEditDate, 'No edits') AS LastEdit,
    ph.Name AS PostHistoryTypeName,
    ut.DisplayName AS LastEditor,
    RPH.Level AS HierarchyLevel
FROM 
    Posts p
LEFT JOIN 
    UserVotes up ON p.Id = up.PostId
LEFT JOIN 
    PostHistorySummary psz ON p.Id = psz.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Users ut ON p.LastEditorUserId = ut.Id
LEFT JOIN 
    RecursivePostHierarchy RPH ON p.Id = RPH.Id
WHERE 
    p.CreationDate >= DATEADD(YEAR, -2, GETDATE())
    AND (p.Tags LIKE '%SQL%' OR p.Tags LIKE '%Database%')
    AND (p.ViewCount > 100 OR p.AnswerCount > 0)
ORDER BY 
    p.ViewCount DESC, 
    UserVoteScore DESC
OPTION (MAXRECURSION 100);
