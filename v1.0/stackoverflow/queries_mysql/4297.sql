
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName, 
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUserStats AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        AnswerCount, 
        QuestionCount, 
        AverageScore, 
        TotalBounties,
        @PostRank := @PostRank + 1 AS PostRank,
        @ScoreRank := @ScoreRank + IF(AverageScore IS NOT NULL, 1, 0) AS ScoreRank
    FROM 
        UserPostStats, (SELECT @PostRank := 0, @ScoreRank := 0) init
    ORDER BY 
        TotalPosts DESC, AverageScore DESC
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS UsageCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
),
TopTags AS (
    SELECT 
        TagName, 
        UsageCount, 
        @TagRank := @TagRank + 1 AS TagRank
    FROM 
        PopularTags, (SELECT @TagRank := 0) init
    ORDER BY 
        UsageCount DESC
)
SELECT 
    r.DisplayName,
    r.TotalPosts,
    r.AnswerCount,
    r.QuestionCount,
    r.AverageScore,
    r.TotalBounties,
    t.TagName,
    t.UsageCount
FROM 
    RankedUserStats r
LEFT JOIN 
    TopTags t ON r.PostRank <= 10 AND t.TagRank <= 5
WHERE 
    r.TotalPosts > 0
ORDER BY 
    r.TotalPosts DESC, 
    r.AverageScore DESC;
