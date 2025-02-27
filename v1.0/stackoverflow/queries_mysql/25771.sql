
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
),
UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(p.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(p.FavoriteCount, 0)) AS TotalFavorites
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
        Tag,
        COUNT(DISTINCT pt.PostId) AS PostCount,
        SUM(COALESCE(up.TotalViews, 0)) AS TotalViewsPerTag,
        SUM(COALESCE(up.TotalAnswers, 0)) AS TotalAnswersPerTag,
        SUM(COALESCE(up.TotalComments, 0)) AS TotalCommentsPerTag,
        SUM(COALESCE(up.TotalFavorites, 0)) AS TotalFavoritesPerTag
    FROM 
        PostTags pt
    LEFT JOIN 
        UserPostStats up ON pt.PostId = up.UserId
    GROUP BY 
        Tag
)
SELECT 
    tp.Tag,
    tp.PostCount,
    tp.TotalViewsPerTag,
    tp.TotalAnswersPerTag,
    tp.TotalCommentsPerTag,
    tp.TotalFavoritesPerTag,
    CASE 
        WHEN tp.PostCount > 0 THEN ROUND(tp.TotalViewsPerTag * 1.0 / tp.PostCount, 2)
        ELSE 0 
    END AS AverageViewsPerPost,
    CASE 
        WHEN tp.PostCount > 0 THEN ROUND(tp.TotalAnswersPerTag * 1.0 / tp.PostCount, 2)
        ELSE 0 
    END AS AverageAnswersPerPost,
    CASE 
        WHEN tp.PostCount > 0 THEN ROUND(tp.TotalCommentsPerTag * 1.0 / tp.PostCount, 2)
        ELSE 0 
    END AS AverageCommentsPerPost,
    CASE 
        WHEN tp.PostCount > 0 THEN ROUND(tp.TotalFavoritesPerTag * 1.0 / tp.PostCount, 2)
        ELSE 0 
    END AS AverageFavoritesPerPost
FROM 
    TagPopularity tp
ORDER BY 
    tp.TotalViewsPerTag DESC, tp.Tag;
