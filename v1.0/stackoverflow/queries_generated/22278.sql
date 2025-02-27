WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8 -- BountyStart
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate BETWEEN NOW() - INTERVAL '2 months' AND NOW()
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title AS PostTitle,
    r.Rank,
    ue.DisplayName AS UserName,
    ue.CommentCount,
    ue.TotalBounty,
    ph.HistoryTypes,
    ph.LastEditDate,
    CASE 
        WHEN r.TotalPosts = 1 THEN 'First Post'
        WHEN r.Rank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostStatus,
    CASE 
        WHEN p.Score IS NULL OR p.Score = 0 THEN 'No Votes'
        ELSE 'Has Votes'
    END AS VoteStatus
FROM 
    RankedPosts r
JOIN 
    Users u ON r.OwnerUserId = u.Id
JOIN 
    UserEngagement ue ON u.Id = ue.UserId
LEFT JOIN 
    PostHistoryAnalysis ph ON r.Id = ph.PostId
WHERE 
    (ue.TotalBounty > 0 OR ue.CommentCount > 5)
    AND r.Rank <= 5
    AND (ph.LastEditDate IS NULL OR ph.LastEditDate > r.CreationDate)
ORDER BY 
    r.Score DESC, 
    ue.TotalBounty DESC;
