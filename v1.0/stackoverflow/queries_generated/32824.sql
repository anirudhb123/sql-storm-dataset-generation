WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
        AND p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        DATEDIFF(DAY, MIN(ph.CreationDate), GETDATE()) AS AgeInDays
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserStatistics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.Views) AS TotalViews,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        (SUM(u.UpVotes) - SUM(u.DownVotes)) AS NetVotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    phd.ClosedDate,
    phd.AgeInDays,
    us.DisplayName AS OwnerDisplayName,
    us.TotalViews,
    us.NetVotes,
    CASE 
        WHEN phd.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
JOIN 
    UserStatistics us ON rp.OwnerUserId = us.UserId
WHERE 
    (rp.CommentCount > 10 OR (us.NetVotes > 5 AND us.TotalViews > 100))
    AND (phd.ClosedDate IS NULL OR phd.AgeInDays <= 30)
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
