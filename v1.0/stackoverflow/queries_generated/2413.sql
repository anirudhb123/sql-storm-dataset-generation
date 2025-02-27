WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount,
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
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        AvgViewCount,
        LastPostDate,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserPostStats
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS AuthorName,
        p.PostTypeId,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
RankedRecentPosts AS (
    SELECT 
        rp.*,
        RANK() OVER (PARTITION BY rp.PostTypeId ORDER BY rp.ViewCount DESC) AS PostRank
    FROM 
        RecentPosts rp
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalScore,
    rrp.PostId,
    rrp.Title,
    rrp.Score,
    rrp.ViewCount,
    rrp.CommentCount,
    rrp.PostRank
FROM 
    TopUsers tu
JOIN 
    RankedRecentPosts rrp ON tu.UserId = rrp.SubmittedByUserId
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.TotalScore DESC, 
    rrp.ViewCount DESC;
