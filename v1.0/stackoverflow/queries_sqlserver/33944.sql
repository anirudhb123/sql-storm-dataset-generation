
WITH UserReputationCTE AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        1 AS Level
    FROM 
        Users
    WHERE 
        Reputation > 1000
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        ur.Level + 1
    FROM 
        Users u
    INNER JOIN UserReputationCTE ur ON u.Reputation > ur.Reputation
    WHERE 
        ur.Level < 3
),
MostActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 500
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation AS UserReputation,
    COALESCE(ua.CommentCount, 0) AS TotalComments,
    COALESCE(ua.TotalViews, 0) AS TotalViews,
    tp.Title AS TopPostTitle,
    tp.Score AS TopPostScore
FROM 
    Users u
LEFT JOIN 
    MostActiveUsers ua ON u.Id = ua.Id
LEFT JOIN 
    TopPosts tp ON u.Id = tp.Id
WHERE 
    u.CreationDate < DATEADD(day, -30, '2024-10-01 12:34:56')
AND 
    (u.Location IS NOT NULL OR u.WebsiteUrl IS NOT NULL)
ORDER BY 
    UserReputation DESC,
    TotalViews DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
