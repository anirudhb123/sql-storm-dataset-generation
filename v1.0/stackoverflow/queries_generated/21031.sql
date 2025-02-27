WITH RecursivePostAncestors AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Depth + 1 
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostAncestors r ON p.ParentId = r.PostId
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        r.Depth AS AncestorDepth
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        RecursivePostAncestors r ON p.Id = r.PostId
    GROUP BY 
        p.Id, r.Depth
),
FinalMetrics AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.UpVotes - pm.DownVotes AS VoteBalance,
        pm.CommentCount,
        pm.ClosedDate,
        pm.ReopenedDate,
        CASE 
            WHEN pm.ClosedDate IS NOT NULL AND (pm.ReopenedDate IS NULL OR pm.ClosedDate > pm.ReopenedDate) THEN 'Closed'
            WHEN pm.ReopenedDate IS NOT NULL THEN 'Reopened'
            ELSE 'Open'
        END AS PostStatus,
        pm.AncestorDepth
    FROM 
        PostMetrics pm
)
SELECT 
    f.PostId,
    f.Title,
    f.VoteBalance,
    f.CommentCount,
    f.PostStatus,
    COALESCE(t.TagName, 'Unlabeled') AS TagName,
    CASE 
        WHEN (f.AncestorDepth IS NULL OR f.AncestorDepth = 0) THEN 'No Ancestors'
        ELSE CAST(f.AncestorDepth AS VARCHAR)
    END AS AncestorDepth_Description
FROM 
    FinalMetrics f
LEFT JOIN (
    SELECT 
        p.Id AS PostId, 
        STRING_AGG(t.TagName, ', ') AS TagName
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL unnest(string_to_array(p.Tags, '><')) AS TagName ON TRUE
    JOIN 
        Tags t ON t.TagName = TagName
    WHERE 
        p.PostTypeId = 1  -- Only for questions
    GROUP BY 
        p.Id
) t ON f.PostId = t.PostId
WHERE
    (f.VoteBalance > 5 OR f.CommentCount > 10)
ORDER BY 
    f.VoteBalance DESC, 
    f.CommentCount DESC
LIMIT 100;
