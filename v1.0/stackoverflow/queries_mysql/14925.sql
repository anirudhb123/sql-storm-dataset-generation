
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScorePerPost,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViewsPerPost,
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
        @rankScore := IF(@prevScore = TotalScore, @rankScore, @rankScore + 1) AS ScoreRank,
        @prevScore := TotalScore,
        @rankView := IF(@prevView = TotalViews, @rankView, @rankView + 1) AS ViewRank,
        @prevView := TotalViews
    FROM 
        UserPostStats,
        (SELECT @rankScore := 0, @rankView := 0, @prevScore := NULL, @prevView := NULL) AS vars
    ORDER BY 
        TotalScore DESC, TotalViews DESC
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
