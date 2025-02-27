WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
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
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days' AND 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(pt.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
PostMetrics AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerName,
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        COALESCE(phd.LastEditDate, 'Not Edited') AS LastEditDate,
        COALESCE(phd.HistoryTypes, 'No History') AS HistorySummary
    FROM 
        RecentPosts rp
    LEFT JOIN 
        PostHistoryDetails phd ON rp.Id = phd.PostId
)
SELECT 
    pm.Title,
    pm.OwnerName,
    pm.Score,
    pm.CommentCount,
    pm.UpVotes,
    pm.DownVotes,
    pm.LastEditDate,
    pm.HistorySummary
FROM 
    PostMetrics pm
ORDER BY 
    pm.Score DESC, 
    pm.CommentCount DESC;
