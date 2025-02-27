WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) OVER (PARTITION BY u.Id) AS AvgScore,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS RankByPostCount
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
        TotalViews, 
        AvgScore, 
        RankByPostCount
    FROM 
        UserPostStats
    WHERE 
        RankByPostCount <= 10
),
PostsWithBadges AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        b.UserId,
        b.Name AS BadgeName
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostDetails AS (
    SELECT 
        p.Title, 
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(pl.RelatedPostId) AS RelatedPostCount,
        COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END), 0) AS IsClosed,
        COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END), 0) AS IsReopened
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    tu.DisplayName,
    tu.TotalScore,
    p.Title,
    p.CreationDate,
    p.Score,
    p.CommentCount,
    p.RelatedPostCount,
    p.IsClosed,
    p.IsReopened,
    STRING_AGG(DISTINCT b.BadgeName, ', ') AS Badges
FROM 
    TopUsers tu
JOIN 
    PostsWithBadges p ON tu.UserId = p.UserId
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId
GROUP BY 
    tu.DisplayName, tu.TotalScore, p.Title, p.CreationDate, p.Score, p.CommentCount, p.RelatedPostCount, p.IsClosed, p.IsReopened
ORDER BY 
    tu.TotalScore DESC, p.Score DESC;
