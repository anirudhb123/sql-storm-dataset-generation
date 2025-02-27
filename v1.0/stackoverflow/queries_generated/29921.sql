WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Filtering for Questions
        AND p.CreationDate >= '2023-01-01'  -- Limiting to recent questions
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(rp.PostId) AS TotalPosts,
        SUM(rp.ViewCount) AS TotalViews,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.AnswerCount) AS AvgAnswers,
        SUM(rp.CommentCount) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalViews,
        ups.TotalScore,
        ups.AvgAnswers,
        ups.TotalComments,
        RANK() OVER (ORDER BY ups.TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats ups
    WHERE 
        ups.TotalPosts > 0  -- Only including users with posts
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalViews,
    tu.TotalScore,
    tu.AvgAnswers,
    tu.TotalComments,
    tu.ScoreRank,
    STRING_AGG(DISTINCT tg.TagName, ', ') AS TagsUsed
FROM 
    TopUsers tu
JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName
    ) AS tg ON true
WHERE 
    p.CreationDate >= '2023-01-01'  -- Ensuring to use recent posts for tags
GROUP BY 
    tu.UserId, tu.DisplayName, tu.TotalPosts, tu.TotalViews, tu.TotalScore, tu.AvgAnswers, tu.TotalComments, tu.ScoreRank
ORDER BY 
    tu.ScoreRank;
