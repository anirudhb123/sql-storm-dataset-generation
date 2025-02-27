WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate AS UserCreationDate,
        SUM(CASE WHEN r.UserPostRank IS NOT NULL THEN 1 ELSE 0 END) AS UserPostCount,
        SUM(r.Score) AS TotalScore,
        SUM(r.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts r ON u.Id = r.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.UserCreationDate,
    us.UserPostCount,
    us.TotalScore,
    us.TotalViews,
    pht.Name AS PostHistoryTypeName,
    COUNT(ph.Id) AS HistoryItemCount
FROM 
    UserStatistics us
LEFT JOIN 
    PostHistory ph ON us.UserId = ph.UserId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    us.UserPostCount > 5
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation, us.UserCreationDate, pht.Name
ORDER BY 
    us.TotalScore DESC, us.UserPostCount DESC
LIMIT 10;
