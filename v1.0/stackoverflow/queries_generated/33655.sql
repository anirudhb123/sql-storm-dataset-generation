WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        0 AS Level,
        CAST(Title AS VARCHAR(MAX)) AS Path
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1,
        CAST(r.Path + ' > ' + p.Title AS VARCHAR(MAX))
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.Id
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
),
VoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditedDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS EditTypes
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
),
TagUsage AS (
    SELECT 
        tag.TagName, 
        COUNT(*) AS PostCount
    FROM Tags tag
    JOIN Posts p ON p.Tags ILIKE '%' || tag.TagName || '%'
    GROUP BY tag.TagName
    ORDER BY PostCount DESC
    LIMIT 10
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    COALESCE(v.UpVotes, 0) AS NumberOfUpVotes,
    COALESCE(v.DownVotes, 0) AS NumberOfDownVotes,
    ph.EditCount AS TotalEdits,
    ph.LastEditedDate,
    th.Path AS PostHierarchyPath,
    t.TagName,
    t.PostCount AS TagUsageCount
FROM Posts p
LEFT JOIN VoteSummary v ON p.Id = v.PostId
LEFT JOIN PostHistoryDetails ph ON p.Id = ph.PostId
LEFT JOIN RecursivePostHierarchy th ON p.Id = th.Id
LEFT JOIN TagUsage t ON p.Tags ILIKE '%' || t.TagName || '%'
WHERE (
    p.CreationDate >= NOW() - INTERVAL '1 year' AND 
    (v.UpVotes IS NOT NULL OR v.DownVotes IS NOT NULL)
)
ORDER BY p.CreationDate DESC;
