WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
), 
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(rp.PostId) AS QuestionCount,
        SUM(rp.ViewCount) AS TotalViews,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.TagCount) AS AvgTagsPerPost
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        TotalViews,
        TotalScore,
        AvgTagsPerPost,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.QuestionCount,
    t.TotalViews,
    t.TotalScore,
    ROUND(t.AvgTagsPerPost, 2) AS AvgTagsPerPost,
    (SELECT STRING_AGG(DISTINCT p.Title, ', ') 
     FROM Posts p 
     WHERE p.OwnerUserId = t.UserId 
     AND p.PostTypeId = 1 
     AND p.Score = (SELECT MAX(Score) FROM Posts WHERE OwnerUserId = t.UserId AND PostTypeId = 1)) AS BestPerformingPost
FROM 
    TopUsers t
WHERE 
    t.ScoreRank <= 10 -- Top 10 users by score
ORDER BY 
    t.TotalScore DESC;
