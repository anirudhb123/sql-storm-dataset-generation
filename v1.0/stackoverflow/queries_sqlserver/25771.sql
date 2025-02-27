
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        value AS Tag
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS Value
    WHERE 
        p.PostTypeId = 1 
),
UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(ISNULL(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(ISNULL(p.CommentCount, 0)) AS TotalComments,
        SUM(ISNULL(p.FavoriteCount, 0)) AS TotalFavorites
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
),
TagPopularity AS (
    SELECT 
        pt.Tag,
        COUNT(DISTINCT pt.PostId) AS PostCount,
        SUM(ISNULL(up.TotalViews, 0)) AS TotalViewsPerTag,
        SUM(ISNULL(up.TotalAnswers, 0)) AS TotalAnswersPerTag,
        SUM(ISNULL(up.TotalComments, 0)) AS TotalCommentsPerTag,
        SUM(ISNULL(up.TotalFavorites, 0)) AS TotalFavoritesPerTag
    FROM 
        PostTags pt
    LEFT JOIN 
        UserPostStats up ON pt.PostId = up.UserId
    GROUP BY 
        pt.Tag
)
SELECT 
    tp.Tag,
    tp.PostCount,
    tp.TotalViewsPerTag,
    tp.TotalAnswersPerTag,
    tp.TotalCommentsPerTag,
    tp.TotalFavoritesPerTag,
    CASE 
        WHEN tp.PostCount > 0 THEN ROUND(CAST(tp.TotalViewsPerTag AS FLOAT) / tp.PostCount, 2)
        ELSE 0 
    END AS AverageViewsPerPost,
    CASE 
        WHEN tp.PostCount > 0 THEN ROUND(CAST(tp.TotalAnswersPerTag AS FLOAT) / tp.PostCount, 2)
        ELSE 0 
    END AS AverageAnswersPerPost,
    CASE 
        WHEN tp.PostCount > 0 THEN ROUND(CAST(tp.TotalCommentsPerTag AS FLOAT) / tp.PostCount, 2)
        ELSE 0 
    END AS AverageCommentsPerPost,
    CASE 
        WHEN tp.PostCount > 0 THEN ROUND(CAST(tp.TotalFavoritesPerTag AS FLOAT) / tp.PostCount, 2)
        ELSE 0 
    END AS AverageFavoritesPerPost
FROM 
    TagPopularity tp
ORDER BY 
    tp.TotalViewsPerTag DESC, tp.Tag;
