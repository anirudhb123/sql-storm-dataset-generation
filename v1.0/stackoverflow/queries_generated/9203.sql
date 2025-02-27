WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Body,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '> <')) AS tagName ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tagName
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
), FilteredPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        string_agg(DISTINCT pht.Name, ', ') AS ChangeTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
), PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerName,
        COALESCE(fp.ChangeCount, 0) AS TotalChanges,
        COALESCE(fp.ChangeTypes, 'No Changes') AS ChangeSummary
    FROM 
        RankedPosts rp
    LEFT JOIN 
        FilteredPostHistory fp ON rp.PostId = fp.PostId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.OwnerName,
    pm.TotalChanges,
    pm.ChangeSummary
FROM 
    PostMetrics pm
ORDER BY 
    pm.Score DESC, pm.ViewCount DESC;
