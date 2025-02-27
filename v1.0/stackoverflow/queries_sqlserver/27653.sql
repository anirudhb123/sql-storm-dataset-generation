
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS APPLY 
        STRING_SPLIT(p.Tags, '><') AS tag_name
    LEFT JOIN 
        Tags t ON t.TagName = tag_name.value
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate
    ORDER BY 
        VoteCount DESC, 
        CommentCount DESC
    OFFSET 0 ROWS 
    FETCH NEXT 10 ROWS ONLY
),
RecentActivities AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        pt.Name AS ChangeType,
        ph.UserDisplayName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= DATEADD(MONTH, -1, '2024-10-01 12:34:56')  
        AND ph.PostId IN (SELECT PostId FROM RankedPosts)
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.CommentCount,
    rp.VoteCount,
    rp.Tags,
    ra.HistoryDate,
    ra.ChangeType,
    ra.UserDisplayName,
    ra.Comment
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivities ra ON rp.PostId = ra.PostId
ORDER BY 
    rp.VoteCount DESC, 
    rp.CommentCount DESC, 
    ra.HistoryDate DESC;
