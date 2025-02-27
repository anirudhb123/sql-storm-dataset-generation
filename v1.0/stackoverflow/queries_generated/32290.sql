WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        COALESCE(b.Name, 'No Badge') AS OwnerBadge,
        rp.CommentCount,
        (SELECT AVG(v.BountyAmount) 
         FROM Votes v 
         WHERE v.PostId = rp.PostId AND v.VoteTypeId = 8) AS AverageBounty
    FROM 
        RankedPosts rp
    LEFT JOIN Badges b ON rp.OwnerUserId = b.UserId AND b.Class = 1 -- Gold badge
    WHERE 
        rp.PostRank <= 5 -- top 5 posts per type
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score AS TotalScore,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.OwnerBadge,
    tp.CommentCount,
    CASE 
        WHEN tp.CommentCount > 0 THEN 'Comments present'
        ELSE 'No comments'
    END AS CommentsStatus,
    CASE 
        WHEN tp.AverageBounty IS NULL THEN 'No bounty offered'
        ELSE CONCAT('Avg Bounty: ', tp.AverageBounty)
    END AS BountyInfo
FROM 
    TopPosts tp
WHERE 
    tp.Score > 10
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
LIMIT 50;

-- Fetch Posts with Complex Relationships
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId
    FROM 
        Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.Id
)
SELECT 
    ph.Id AS ChildPostId,
    ph.Title AS ChildPostTitle,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ph.Id) AS ChildCommentCount,
    p.Title AS ParentPostTitle
FROM 
    PostHierarchy ph
LEFT JOIN Posts p ON ph.ParentId = p.Id
WHERE 
    ph.ParentId IS NOT NULL
ORDER BY 
    ChildCommentCount DESC;
