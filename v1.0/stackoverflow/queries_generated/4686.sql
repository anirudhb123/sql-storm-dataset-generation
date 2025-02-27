WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    WHERE 
        p.Score > 10 AND 
        p.CreationDate BETWEEN now() - INTERVAL '1 year' AND now()
),
PostMetrics AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        PostTypeId,
        Score,
        ViewCount,
        rn,
        CommentCount,
        TotalBounty,
        CASE 
            WHEN TotalBounty IS NULL THEN 'No Bounties'
            ELSE 'Has Bounties'
        END AS BountyStatus
    FROM 
        RankedPosts
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.PostTypeId,
    pm.Score,
    pm.ViewCount,
    pm.CommentCount,
    pm.TotalBounty,
    pm.BountyStatus
FROM 
    PostMetrics pm
WHERE 
    pm.rn <= 5 OR 
    pm.BountyStatus = 'Has Bounties'
ORDER BY 
    pm.PostTypeId, pm.Score DESC
UNION ALL
SELECT 
    NULL AS PostId,
    NULL AS Title,
    NULL AS CreationDate,
    NULL AS PostTypeId,
    COUNT(*) AS TotalPosts,
    NULL AS ViewCount,
    NULL AS CommentCount,
    NULL AS TotalBounty,
    'Summary' AS BountyStatus
FROM 
    Posts
WHERE 
    CreationDate < now() - INTERVAL '1 year'
GROUP BY 
    NULL
HAVING 
    COUNT(*) > 0;
