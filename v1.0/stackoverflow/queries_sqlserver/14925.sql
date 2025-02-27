
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(ISNULL(p.Score, 0)) AS TotalScore,
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        AVG(ISNULL(p.Score, 0)) AS AvgScorePerPost,
        AVG(ISNULL(p.ViewCount, 0)) AS AvgViewsPerPost,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
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
        AvgScorePerPost,
        AvgViewsPerPost,
        CommentCount,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        UserPostStats
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    TotalViews,
    AvgScorePerPost,
    AvgViewsPerPost,
    CommentCount,
    ScoreRank,
    ViewRank
FROM 
    TopUsers
WHERE 
    ScoreRank <= 10 OR ViewRank <= 10
ORDER BY 
    ScoreRank, ViewRank;
