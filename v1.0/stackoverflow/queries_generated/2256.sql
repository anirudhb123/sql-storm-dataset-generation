WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.*,
        u.Reputation AS OwnerReputation,
        COALESCE(b.Name, 'No Badge') AS UserBadge
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1 -- Gold Badge
    WHERE 
        rp.Rank <= 5
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        ph.Comment,
        ph.Text AS OldValue,
        ph.PostHistoryTypeId
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10) -- Edit Title, Edit Body, Post Closed
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CreationDate AS PostDate,
    tp.OwnerReputation,
    tp.UserBadge,
    phd.UserDisplayName AS EditorName,
    phd.EditDate,
    CASE 
        WHEN phd.PostHistoryTypeId = 10 THEN 'Closed'
        ELSE 'Edited'
    END AS EditType,
    phd.OldValue
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistoryData phd ON tp.PostId = phd.PostId
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC NULLS LAST
LIMIT 50;
