WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) FILTER (WHERE v.BountyAmount IS NOT NULL) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- BountyStart and BountyClose
    GROUP BY 
        p.Id, u.DisplayName
),
RecentClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        p.Title AS ClosedTitle,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
        AND ph.CreationDate >= NOW() - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.AverageBounty,
        COALESCE(rp.ViewCount / NULLIF(rp.Score, 0), 0) AS ViewsPerScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
        AND rp.Score > 0
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.AverageBounty,
    tp.ViewsPerScore,
    rcp.ClosedTitle,
    rcp.ClosedDate,
    rcp.ClosedBy,
    rcp.CloseReason
FROM 
    TopPosts tp
LEFT JOIN 
    RecentClosedPosts rcp ON tp.PostId = rcp.ClosedPostId
WHERE 
    tp.ViewsPerScore > 1.5
ORDER BY 
    tp.Score DESC,
    tp.ViewCount DESC
LIMIT 100;

-- The above SQL performs the following logic:
-- 1. Creates a CTE of posts ranked by creation date within their type, calculating the number of comments and average bounty.
-- 2. Creates another CTE to capture recent closed posts and their details.
-- 3. Filters the top ranked posts based on the number of views per score while also capturing data on closed posts (if applicable).
