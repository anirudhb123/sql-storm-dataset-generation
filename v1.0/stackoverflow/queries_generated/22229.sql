WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS Deletions
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostCloseDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON ph.Comment::INT = c.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId, ph.UserId, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    rp.TotalBounty,
    rp.UpVotes,
    rp.DownVotes,
    rp.Deletion,
    COALESCE(pcd.CloseReasons, 'No Closure') AS CloseReasonDetails,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Latest Post by User'
        ELSE 'Not the Latest Post' 
    END AS UserPostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostCloseDetails pcd ON rp.PostId = pcd.PostId
WHERE 
    rp.ViewCount > 100
ORDER BY 
    rp.TotalBounty DESC NULLS LAST,
    rp.ViewCount ASC NULLS FIRST
LIMIT 50;

-- Additional Aggregate testing with UNION

SELECT 
    'Post' AS PostType,
    SUM(ViewCount) AS TotalViews,
    COUNT(*) AS TotalPosts,
    AVG(ViewCount) AS AvgViewsPerPost
FROM 
    Posts
WHERE 
    CreationDate >= NOW() - INTERVAL '6 months'

UNION ALL

SELECT 
    'Comment' AS PostType,
    SUM(CASE WHEN UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalViews,
    COUNT(*) AS TotalComments,
    AVG(LENGTH(Text)) AS AvgCommentLength
FROM 
    Comments
WHERE 
    CreationDate >= NOW() - INTERVAL '6 months';
