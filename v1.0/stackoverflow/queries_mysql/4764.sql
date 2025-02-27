
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
HighScoreUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        AvgScore,
        TotalViews,
        @rownum := @rownum + 1 AS RankScore
    FROM 
        UserPostStats, (SELECT @rownum := 0) r
    WHERE 
        TotalPosts > 0
    ORDER BY 
        AvgScore DESC
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON FIND_IN_SET(t.TagName, p.Tags)
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.Id) > 10
),
TagStats AS (
    SELECT 
        tt.TagName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT v.UserId) AS UniqueVoters 
    FROM 
        TopTags tt
    LEFT JOIN 
        Votes v ON v.PostId IN (SELECT Id FROM Posts WHERE FIND_IN_SET(tt.TagName, Tags))
    GROUP BY 
        tt.TagName
)
SELECT 
    u.DisplayName AS TopUser,
    u.TotalPosts,
    u.QuestionCount,
    u.AnswerCount,
    u.AvgScore,
    u.TotalViews,
    tt.TagName AS PopularTag,
    ts.TotalBounties,
    ts.UniqueVoters,
    CONCAT('User:', u.DisplayName, '; Tag:', tt.TagName) AS UserTagCombination
FROM 
    HighScoreUsers u
JOIN 
    TopTags tt ON u.QuestionCount > 5
JOIN 
    TagStats ts ON tt.TagName = ts.TagName
WHERE 
    u.RankScore <= 10
ORDER BY 
    u.AvgScore DESC, 
    ts.TotalBounties DESC;
