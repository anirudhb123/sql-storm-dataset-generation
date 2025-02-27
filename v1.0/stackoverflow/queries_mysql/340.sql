
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        @row_number := IF(@current_user_id = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @current_user_id := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS JOIN (SELECT @row_number := 0, @current_user_id := NULL) AS vars
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.LastAccessDate,
        COUNT(DISTINCT p.Id) AS ActivePostCount,
        SUM(IFNULL(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.LastAccessDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.LastAccessDate
)
SELECT 
    au.DisplayName,
    au.Reputation,
    au.ActivePostCount,
    au.TotalViews,
    rp.Title,
    rp.Score,
    rp.CommentCount,
    CASE 
        WHEN au.TotalViews > 1000 THEN 'High Activity'
        WHEN au.TotalViews BETWEEN 500 AND 1000 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel,
    GROUP_CONCAT(DISTINCT ht.Name SEPARATOR ', ') AS HistoryTypes
FROM 
    ActiveUsers au
LEFT JOIN 
    RankedPosts rp ON au.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistory ph ON rp.Id = ph.PostId
LEFT JOIN 
    PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
WHERE 
    rp.Rank <= 3
GROUP BY 
    au.DisplayName, au.Reputation, au.ActivePostCount, au.TotalViews, rp.Title, rp.Score, rp.CommentCount
ORDER BY 
    au.Reputation DESC, au.TotalViews DESC;
