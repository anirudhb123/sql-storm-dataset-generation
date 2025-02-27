WITH RecursivePostHistory AS (
    SELECT 
        ph.Id AS HistoryId,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text,
        1 AS Level
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Considering only close/reopen events
    UNION ALL
    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text,
        Level + 1
    FROM 
        PostHistory ph
    JOIN 
        RecursivePostHistory rph ON ph.Id = rph.HistoryId
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
PostMetrics AS (
    SELECT 
        ra.PostId,
        ra.Title,
        ra.CreationDate,
        ra.CommentCount,
        ra.UpVotes,
        ra.DownVotes,
        ph.UserDisplayName AS LastEditor,
        ph.CreationDate AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY ra.PostId ORDER BY ph.CreationDate DESC) AS RN
    FROM 
        RecentActivity ra
    LEFT JOIN 
        PostHistory ph ON ra.PostId = ph.PostId AND ph.UserId IS NOT NULL 
    WHERE 
        ph.PostHistoryTypeId IN (24, 33)  -- Considering suggested edits and post notice additions
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.CommentCount,
    pm.UpVotes,
    pm.DownVotes,
    pm.LastEditor,
    pm.LastEditDate
FROM 
    PostMetrics pm
WHERE 
    pm.RN = 1
ORDER BY 
    pm.UpVotes DESC, pm.CommentCount DESC;
