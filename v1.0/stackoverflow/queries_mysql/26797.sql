
WITH TagStats AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><', numbers.n), '><', -1)) AS Tag,
        COUNT(*) AS TagCount,
        SUM(ViewCount) AS TotalViews,
        SUM(AnswerCount) AS TotalAnswers
    FROM 
        Posts
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><', numbers.n), '><', -1))
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        SUM(IFNULL(v.BountyAmount, 0)) AS TotalBounty,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (9, 10) 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
), TagUserInfluence AS (
    SELECT 
        ts.Tag,
        us.UserId,
        us.DisplayName AS UserName,
        COUNT(DISTINCT p.Id) AS PostsWithTag,
        SUM(p.Score) AS ScoreWithTag,
        SUM(p.ViewCount) AS ViewsWithTag
    FROM 
        TagStats ts
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', ts.Tag, '%')
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        UserStats us ON u.Id = us.UserId
    GROUP BY 
        ts.Tag, us.UserId, us.DisplayName
)
SELECT 
    tü.Tag,
    tü.UserName,
    tü.PostsWithTag,
    tü.ScoreWithTag,
    tü.ViewsWithTag,
    ts.TagCount,
    ts.TotalViews,
    ts.TotalAnswers,
    (CAST(tü.ScoreWithTag AS DECIMAL) / NULLIF(tü.PostsWithTag, 0)) AS AvgScorePerPost,
    (CAST(tü.ViewsWithTag AS DECIMAL) / NULLIF(tü.PostsWithTag, 0)) AS AvgViewsPerPost,
    (CAST(u.QuestionCount AS DECIMAL) / NULLIF(u.TotalScore, 0)) AS ScoreEfficiency
FROM 
    TagUserInfluence tü
JOIN 
    TagStats ts ON tü.Tag = ts.Tag
JOIN 
    UserStats u ON tü.UserId = u.UserId
WHERE 
    tü.PostsWithTag > 0
ORDER BY 
    ts.TotalViews DESC, AvgScorePerPost DESC;
