WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(DISTINCT v.UserId) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- UpMod votes only
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
RecentPostHistories AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        pht.Name AS HistoryType,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.Rank,
    COALESCE(rph.UserId, -1) AS LastEditorUserId,
    COALESCE(rph.HistoryType, 'No changes') AS LastEditType,
    COALESCE(rph.Comment, 'No comments') AS LastEditComment,
    rp.VoteCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentPostHistories rph ON rp.PostId = rph.PostId
WHERE 
    rp.Rank <= 5 -- Top 5 posts by score per type
ORDER BY 
    rp.PostId, rp.Score DESC;

-- Evaluate post interaction metrics
WITH PostInteractionMetrics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    pim.PostId,
    pim.CommentCount,
    pim.UpvoteCount,
    pim.DownvoteCount,
    pim.AverageBounty,
    CASE
        WHEN pim.CommentCount > 10 THEN 'Highly Engaged'
        WHEN pim.UpvoteCount > 50 THEN 'Popular'
        ELSE 'Moderate Engagement'
    END AS EngagementLevel
FROM 
    PostInteractionMetrics pim
WHERE 
    pim.PostId IN (SELECT PostId FROM RankedPosts WHERE Rank <= 5)
ORDER BY 
    pim.UpvoteCount DESC
LIMIT 10;
