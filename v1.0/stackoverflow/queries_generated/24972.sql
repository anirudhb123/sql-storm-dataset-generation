WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        AVG(COALESCE(p.ViewCount, 1)) AS AvgViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        AvgViews,
        LastPostDate,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY PostCount DESC) AS PostCountRank
    FROM 
        UserPostStats
),

PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS CloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteCount,
        COUNT(DISTINCT ph.UserId) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),

NoRecentActivity AS (
    SELECT 
        UserId,
        DisplayName,
        LastPostDate
    FROM 
        TopUsers
    WHERE 
        LastPostDate < NOW() - INTERVAL '1 year'
),

BizarreCases AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUBSTRING(Tags FROM '#<(\w+)#>')::varchar, 'No Tag') AS MainTag,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN ph.Text IS NULL THEN 1 ELSE 0 END) AS NullTextHistoryCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY COALESCE(ph.CreationDate, p.CreationDate) DESC) AS RevOrder
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
    HAVING 
        COUNT(DISTINCT c.Id) > 5 AND SUM(COALESCE(ph.PostHistoryTypeId, 0)) % 2 = 0
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.TotalScore,
    ph.CloseDate,
    ph.ReopenDate,
    ph.DeleteCount,
    ph.EditCount,
    CASE 
        WHEN n.UserId IS NOT NULL THEN 'Inactive User'
        ELSE 'Active User'
    END AS UserStatus,
    b.PostId,
    b.MainTag,
    b.CommentCount,
    b.NullTextHistoryCount,
    b.RevOrder
FROM 
    TopUsers u
LEFT JOIN 
    PostHistoryStats ph ON u.UserId = ph.PostId
LEFT JOIN 
    NoRecentActivity n ON u.UserId = n.UserId
LEFT JOIN 
    BizarreCases b ON b.PostId = ph.PostId
WHERE 
    (u.ScoreRank < 6 OR u.PostCountRank < 6)
ORDER BY 
    u.TotalScore DESC, 
    u.PostCount DESC, 
    b.CommentCount DESC;
