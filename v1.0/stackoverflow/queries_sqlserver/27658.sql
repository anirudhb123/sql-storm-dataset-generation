
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    OUTER APPLY (
        SELECT value AS tag 
        FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags)-2), '>') 
    ) AS tag
    LEFT JOIN 
        Tags t ON tag.tag = t.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEdited,
        COUNT(*) AS EditCount,
        STRING_AGG(CONCAT(ph.UserDisplayName, ': ', ph.Comment), ' | ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS ClosedDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.RankByViews,
    rp.Tags,
    rph.LastEdited,
    rph.EditCount,
    rph.EditComments,
    cp.ClosedDate,
    cp.CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.RankByViews <= 5 
ORDER BY 
    rp.OwnerUserId, rp.ViewCount DESC;
