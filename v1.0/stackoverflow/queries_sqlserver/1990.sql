
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST(DATEADD(year, -1, '2024-10-01') AS DATE)
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(v.BountyAmount) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        ph.Text,
        p.Title
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= CAST(DATEADD(month, -6, '2024-10-01') AS DATE)
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    COUNT(DISTINCT r.PostId) AS UserTopPosts,
    COALESCE(SUM(phd.TotalChanges), 0) AS RecentPostEdits,
    COALESCE(AVG(r.Score), 0) AS AvgPostScore,
    COUNT(DISTINCT ph.PostId) AS RecentPostHistoryCount
FROM 
    TopUsers ru
LEFT JOIN 
    RankedPosts r ON ru.UserId = r.PostId AND r.ScoreRank <= 10
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS TotalChanges 
     FROM PostHistory 
     WHERE CreationDate >= CAST(DATEADD(day, -30, '2024-10-01') AS DATE)
     GROUP BY PostId) phd ON r.PostId = phd.PostId
LEFT JOIN 
    PostHistoryDetails ph ON ru.UserId = ph.UserId
GROUP BY 
    ru.UserId, ru.DisplayName
ORDER BY 
    UserTopPosts DESC, AvgPostScore DESC;
