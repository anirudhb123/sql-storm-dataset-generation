
WITH UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(c.Id) AS TotalComments,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ExpandedUserStatistics AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalViews,
        TotalComments,
        TotalBadges,
        @scoreRank := IF(@prevScore = TotalScore, @scoreRank, @rankCounter) AS ScoreRank,
        @prevScore := TotalScore,
        @rankCounter := @rankCounter + 1
    FROM 
        (SELECT @scoreRank := 0, @prevScore := NULL, @rankCounter := 1) AS vars,
        UserPostStatistics
    ORDER BY 
        TotalScore DESC
),
FilteredUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalViews,
        TotalComments,
        TotalBadges,
        ScoreRank,
        @postRank := IF(@prevPosts = TotalPosts, @postRank, @postCounter) AS PostRank,
        @prevPosts := TotalPosts,
        @postCounter := @postCounter + 1
    FROM 
        (SELECT @postRank := 0, @prevPosts := NULL, @postCounter := 1) AS vars,
        ExpandedUserStatistics
    WHERE 
        TotalPosts >= 10 
        AND TotalViews >= 100
    ORDER BY 
        TotalPosts DESC
)
SELECT
    fu.DisplayName,
    fu.TotalPosts,
    fu.TotalQuestions,
    fu.TotalAnswers,
    fu.TotalScore,
    fu.TotalViews,
    fu.TotalComments,
    fu.TotalBadges,
    CONCAT('Rank by Score: ', fu.ScoreRank, ', Rank by Posts: ', fu.PostRank) AS RankDetails
FROM 
    FilteredUsers fu
ORDER BY 
    TotalScore DESC, TotalViews DESC;
