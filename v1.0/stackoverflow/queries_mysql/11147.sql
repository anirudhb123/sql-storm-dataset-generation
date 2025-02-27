
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(Id) AS CommentCount 
         FROM 
             Comments 
         GROUP BY 
             PostId) c ON p.Id = c.PostId
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
        TotalComments,
        @ScoreRank := IF(@prevScore = TotalScore, @ScoreRank, @rowNum) AS ScoreRank,
        @prevScore := TotalScore,
        @rowNum := @rowNum + 1 AS rn
    FROM 
        UserPostStats, (SELECT @prevScore := NULL, @ScoreRank := 0, @rowNum := 0) r
    ORDER BY 
        TotalScore DESC
),
RankedViews AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalScore,
        TotalViews,
        TotalComments,
        ScoreRank,
        @ViewsRank := IF(@prevViews = TotalViews, @ViewsRank, @rowViewNum) AS ViewsRank,
        @prevViews := TotalViews,
        @rowViewNum := @rowViewNum + 1 AS rvn
    FROM 
        TopUsers, (SELECT @prevViews := NULL, @ViewsRank := 0, @rowViewNum := 0) v
    ORDER BY 
        TotalViews DESC
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    TotalViews,
    TotalComments,
    ScoreRank,
    ViewsRank
FROM 
    RankedViews
WHERE 
    ScoreRank <= 10 OR ViewsRank <= 10
ORDER BY 
    ScoreRank, ViewsRank;
