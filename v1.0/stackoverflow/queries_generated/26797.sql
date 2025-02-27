WITH TagStats AS (
    SELECT 
        TRIM(UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')))::VARCHAR) AS Tag,
        COUNT(*) AS TagCount,
        SUM(ViewCount) AS TotalViews,
        SUM(AnswerCount) AS TotalAnswers
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only considering questions
    GROUP BY 
        Tag
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (9, 10) -- Considering only BountyClose and Deletion
    WHERE 
        p.PostTypeId = 1 -- Only considering questions
    GROUP BY 
        u.Id
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
        Posts p ON p.Tags LIKE '%' || ts.Tag || '%'
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
    (tü.ScoreWithTag::FLOAT / NULLIF(tü.PostsWithTag, 0)) AS AvgScorePerPost,
    (tü.ViewsWithTag::FLOAT / NULLIF(tü.PostsWithTag, 0)) AS AvgViewsPerPost,
    (u.QuestionCount::FLOAT / NULLIF(u.TotalScore, 0)) AS ScoreEfficiency
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
