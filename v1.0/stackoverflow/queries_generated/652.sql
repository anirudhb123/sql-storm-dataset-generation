WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PostMetrics AS (
    SELECT 
        p.Id,
        MAX(b.Class) AS HighestBadge,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AverageUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    pm.HighestBadge,
    pm.AverageUpvotes,
    pm.TotalDownvotes,
    CASE 
        WHEN pm.AverageUpvotes IS NULL THEN 'No Upvotes'
        ELSE 'Has Upvotes'
    END AS UpvoteStatus
FROM 
    RankedPosts rp
JOIN 
    PostMetrics pm ON rp.Id = pm.Id
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.ViewCount DESC
LIMIT 100;

WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        COUNT(com.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments com ON p.Id = com.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
TopComments AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(c.Text, '; ') AS AllComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rc.CommentCount,
    tp.AllComments,
    rp.UpVoteCount
FROM 
    RecentPosts rp
JOIN 
    TopComments tp ON rp.Id = tp.PostId
ORDER BY 
    rp.CommentCount DESC, rp.UpVoteCount DESC
LIMIT 50;
