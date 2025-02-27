WITH PopularPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.Tags,
        U.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS rn
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
        AND P.PostTypeId = 1 -- Only Questions
),
TaggedPosts AS (
    SELECT 
        PP.Id,
        PP.Title,
        PP.Score,
        PP.ViewCount,
        PP.AnswerCount,
        PP.CommentCount,
        unnest(string_to_array(PP.Tags, '>')) AS Tag,
        PP.Author
    FROM 
        PopularPosts PP
    WHERE 
        PP.rn <= 5 -- Top 5 posts per type
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM 
        TaggedPosts
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC, TotalViews DESC) AS TagRank
    FROM 
        TagStatistics
),
FinalReport AS (
    SELECT 
        TT.Tag,
        TT.PostCount,
        TT.TotalViews,
        TT.TotalScore,
        (TT.TotalScore::decimal / NULLIF(TT.PostCount, 0)) AS AverageScorePerPost,
        (TT.TotalViews::decimal / NULLIF(TT.PostCount, 0)) AS AverageViewsPerPost
    FROM 
        TopTags TT
    WHERE 
        TT.TagRank <= 10
)
SELECT 
    FR.Tag,
    FR.PostCount,
    FR.TotalViews,
    FR.TotalScore,
    FR.AverageScorePerPost,
    FR.AverageViewsPerPost
FROM 
    FinalReport FR
ORDER BY 
    FR.TotalScore DESC;
