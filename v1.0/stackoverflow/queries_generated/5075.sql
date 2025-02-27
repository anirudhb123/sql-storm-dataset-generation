WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerName,
        ViewCount,
        Score
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
PostStatistics AS (
    SELECT 
        pp.OwnerName,
        COUNT(pp.PostId) AS TotalPosts,
        SUM(pp.ViewCount) AS TotalViews,
        AVG(pp.Score) AS AverageScore
    FROM 
        TopPosts pp
    GROUP BY 
        pp.OwnerName
)
SELECT 
    ps.OwnerName,
    ps.TotalPosts,
    ps.TotalViews,
    ps.AverageScore,
    u.Reputation,
    u.CreationDate AS UserCreationDate,
    COUNT(b.Id) AS BadgeCount
FROM 
    PostStatistics ps
JOIN 
    Users u ON ps.OwnerName = u.DisplayName
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    ps.OwnerName, u.Reputation, u.CreationDate
ORDER BY 
    ps.TotalViews DESC, ps.AverageScore DESC;
