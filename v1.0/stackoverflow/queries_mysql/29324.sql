
WITH TagStatistics AS (
    SELECT 
        TRIM(tag) AS TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    JOIN 
        (SELECT 
             SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS tag,
             Id
         FROM 
             Posts
         JOIN 
             (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
              UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
         ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
         WHERE 
             PostTypeId = 1) AS tags ON p.Id = tags.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        TRIM(tag)
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        CommentCount,
        TotalViews,
        TotalUpvotes,
        TotalDownvotes,
        AverageScore,
        @rankByPosts := IF(PostCount = @prevCount, @rankByPosts, @rankByPosts + 1) AS RankByPosts,
        @prevCount := PostCount,
        @rankByScore := IF(AverageScore = @prevScore, @rankByScore, @rankByScore + 1) AS RankByScore,
        @prevScore := AverageScore
    FROM 
        (SELECT @rankByPosts := 0, @prevCount := NULL, @rankByScore := 0, @prevScore := NULL) AS vars,
        TagStatistics
    ORDER BY 
        PostCount DESC, AverageScore DESC
)
SELECT 
    TT.TagName,
    TT.PostCount,
    TT.CommentCount,
    TT.TotalViews,
    TT.TotalUpvotes,
    TT.TotalDownvotes,
    TT.AverageScore,
    CASE 
        WHEN RankByPosts <= 10 THEN 'Top 10 by Posts'
        WHEN RankByScore <= 10 THEN 'Top 10 by Score'
        ELSE 'Other'
    END AS TagCategory
FROM 
    TopTags TT
ORDER BY 
    TT.PostCount DESC, TT.AverageScore DESC;
