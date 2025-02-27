WITH TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        SUM(Posts.Score) AS TotalScore,
        COUNT(DISTINCT Comments.Id) AS CommentCount,
        SUM(CASE WHEN Posts.AnswerCount > 0 THEN 1 ELSE 0 END) AS AnsweredQuestions
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '>'))
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    WHERE 
        Posts.PostTypeId = 1  -- Only questions
    GROUP BY 
        Tags.TagName
), TopTags AS (
    SELECT 
        TagName,
        TotalViews,
        TotalScore,
        CommentCount,
        AnsweredQuestions,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY CommentCount DESC) AS CommentRank
    FROM 
        TagStatistics
)
SELECT 
    TagName,
    TotalViews,
    TotalScore,
    CommentCount,
    AnsweredQuestions,
    CASE 
        WHEN ViewRank = 1 THEN 'Top by Views'
        ELSE NULL
    END AS TopViewTag,
    CASE 
        WHEN ScoreRank = 1 THEN 'Top by Score'
        ELSE NULL
    END AS TopScoreTag,
    CASE 
        WHEN CommentRank = 1 THEN 'Top by Comments'
        ELSE NULL
    END AS TopCommentTag
FROM 
    TopTags
WHERE 
    AnsweredQuestions > 0 -- Only consider tags with answered questions
ORDER BY 
    TotalViews DESC, 
    TotalScore DESC, 
    CommentCount DESC;
