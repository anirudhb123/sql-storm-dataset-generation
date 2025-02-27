WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.Score > 0 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.TotalScore,
        us.TotalViews,
        RANK() OVER (ORDER BY us.TotalScore DESC) AS ScoreRank
    FROM 
        UserStats us
    WHERE 
        us.TotalPosts > 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalScore,
    tu.TotalViews,
    COUNT(DISTINCT rp.PostId) AS RecentPostCount,
    SUM(COALESCE(p.Score, 0)) AS RecentPostScore,
    COUNT(DISTINCT CASE WHEN p.AnswerCount > 0 THEN p.Id END) AS AnsweredPostCount,
    SUM(COALESCE(ph.ChangeCount, 0)) AS TotalPostChanges
FROM 
    TopUsers tu 
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId AND rp.UserPostRank <= 5
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
LEFT JOIN 
    PostHistoryDetails ph ON p.Id = ph.PostId
GROUP BY 
    tu.DisplayName, tu.TotalPosts, tu.TotalScore, tu.TotalViews
HAVING 
    SUM(COALESCE(p.Score, 0)) > 50
ORDER BY 
    tu.TotalScore DESC, tu.TotalPosts DESC;
