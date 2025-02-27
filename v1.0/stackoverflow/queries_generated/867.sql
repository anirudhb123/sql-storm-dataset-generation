WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, pt.Name
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS ClosedDate, 
        ph.Comment AS CloseReason 
    FROM 
        PostHistory ph 
    WHERE 
        ph.PostHistoryTypeId = 10
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.LastAccessDate >= CURRENT_DATE - INTERVAL '1 YEAR'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.OwnerDisplayName, 
    rp.CreationDate, 
    rp.Score, 
    rp.ViewCount, 
    rp.CommentCount, 
    rp.Rank, 
    CASE 
        WHEN rp.Rank <= 3 THEN 'Top Contributor'
        ELSE NULL
    END AS ContributorStatus,
    COALESCE(cp.ClosedDate, 'Active') AS PostStatus,
    CASE 
        WHEN cp.CloseReason IS NOT NULL THEN cp.CloseReason
        ELSE 'No Reason Provided'
    END AS CloseReason,
    au.DisplayName AS ActiveUser, 
    au.Reputation AS ActiveUserReputation
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    ActiveUsers au ON au.TotalPosts > 10
WHERE 
    rp.AvgBounty IS NOT NULL
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
