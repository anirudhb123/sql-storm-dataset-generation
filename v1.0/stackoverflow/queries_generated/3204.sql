WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        RecentPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId AND v.VoteTypeId = 8  -- Only consider BountyStart votes
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName
),
FlaggedPosts AS (
    SELECT 
        p.PostId,
        p.Title,
        CASE 
            WHEN COUNT(ph.Id) > 0 THEN 'Flagged'
            ELSE 'Not Flagged'
        END AS FlagStatus
    FROM 
        PostStats p
    LEFT JOIN 
        PostHistory ph ON p.PostId = ph.PostId AND ph.PostHistoryTypeId IN (10, 12) -- Closed or Deleted
    GROUP BY 
        p.PostId, p.Title
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.AverageBounty,
    fp.FlagStatus,
    CASE 
        WHEN ps.AverageBounty IS NULL THEN 'No Bounty'
        ELSE 'Has Bounty'
    END AS BountyStatus,
    RANK() OVER (ORDER BY ps.CommentCount DESC) AS CommentRank
FROM 
    PostStats ps
JOIN 
    FlaggedPosts fp ON ps.PostId = fp.PostId
WHERE 
    ps.ViewCount > 100
ORDER BY 
    ps.CommentCount DESC,
    ps.ViewCount DESC
LIMIT 10;
