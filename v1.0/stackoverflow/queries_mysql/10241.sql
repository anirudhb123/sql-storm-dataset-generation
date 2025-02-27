
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewsPerPost,
        AVG(p.Score) AS AvgScorePerPost
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
        TotalViews,
        TotalScore,
        AvgViewsPerPost,
        AvgScorePerPost,
        @row_number := IF(@prev_post_count = PostCount, @row_number, @row_number + 1) AS UserRank,
        @prev_post_count := PostCount
    FROM 
        UserPostStats, (SELECT @row_number := 0, @prev_post_count := NULL) AS vars
    ORDER BY 
        PostCount DESC
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalViews,
    TotalScore,
    AvgViewsPerPost,
    AvgScorePerPost
FROM 
    TopUsers
WHERE 
    UserRank <= 10
ORDER BY 
    UserRank;
