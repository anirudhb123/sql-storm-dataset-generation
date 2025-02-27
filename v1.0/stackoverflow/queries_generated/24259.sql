WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level,
        CAST(p.Title AS VARCHAR(MAX)) AS Path 
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1,
        CAST(r.Path + ' -> ' + p.Title AS VARCHAR(MAX)) AS Path
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVoteSummary AS (
    SELECT
        p.Id AS PostId,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Score
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(s.UpVotes, 0) - COALESCE(s.DownVotes, 0) AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY COALESCE(s.UpVotes, 0) - COALESCE(s.DownVotes, 0) DESC, p.ViewCount DESC) AS RN 
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteSummary s ON p.Id = s.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 DAYS'
)

SELECT 
    r.PostId,
    r.Title, 
    r.Level,
    r.Path,
    t.ViewCount, 
    t.NetVotes
FROM 
    RecursivePostHierarchy r
JOIN 
    TopPosts t ON r.PostId = t.Id
WHERE 
    r.Path LIKE '%SQL%' 
    OR EXISTS (
        SELECT 1 
        FROM Comments c 
        WHERE c.PostId = r.PostId AND c.Text ILIKE '%performance%'
    )
ORDER BY 
    r.Level,
    t.NetVotes DESC,
    t.ViewCount DESC;

-- Additional Query for Post History Analysis
WITH PostHistoryStats AS (
    SELECT
        ph.PostId,
        COUNT(*) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS TitleOrBodyEdits,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeletionCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    p.Id AS PostId,
    p.Title,
    phs.EditCount,
    phs.TitleOrBodyEdits,
    phs.DeletionCount,
    COALESCE(SUM(b.Class), 0) AS TotalBadgeCount
FROM 
    Posts p
LEFT JOIN 
    PostHistoryStats phs ON p.Id = phs.PostId
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
GROUP BY 
    p.Id, phs.EditCount, phs.TitleOrBodyEdits, phs.DeletionCount
HAVING 
    phs.EditCount > 0 AND phs.DeletionCount < 5
ORDER BY 
    TotalBadgeCount DESC, Title DESC;
