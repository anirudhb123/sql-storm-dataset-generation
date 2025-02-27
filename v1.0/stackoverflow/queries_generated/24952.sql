WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS TotalUpvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostHistoryTypes,
        COUNT(*) AS HistoryCount,
        MAX(CASE WHEN ph.CreationDate < NOW() - INTERVAL '30 days' THEN 1 ELSE 0 END) AS IsStale
    FROM 
        PostHistory ph
    INNER JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ua.DisplayName AS Owner,
    ua.TotalBounties,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    phd.PostHistoryTypes,
    phd.HistoryCount,
    CASE 
        WHEN phd.IsStale = 1 THEN 'Stale'
        ELSE 'Fresh'
    END AS Status,
    CASE 
        WHEN rp.CommentCount = 0 THEN 'No Comments'
        ELSE CONCAT(rp.CommentCount, ' Comment(s)')
    END AS CommentSummary
FROM 
    RankedPosts rp
JOIN 
    UserActivity ua ON rp.OwnerUserId = ua.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.Rank <= 5 -- Top 5 posts per type
ORDER BY 
    rp.PostId DESC
OPTION (MAXRECURSION 0);
